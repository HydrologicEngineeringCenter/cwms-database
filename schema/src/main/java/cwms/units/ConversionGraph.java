/**
 * Derived from code at https://github.com/MikeNeilson/housedb/blob/main/database/src/main/java/db/migration/java/units/R__unit_conversions.java
 *  
 * Copyright 2022 Michael Neilson
 * Licensed Under MIT License. https://github.com/MikeNeilson/housedb/LICENSE.md
 * For original checkin. Fu
 */
 
package cwms.units;

import java.util.ArrayDeque;
import java.util.Comparator;
import java.util.Deque;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Optional;
import java.util.Queue;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.logging.Logger;
import java.util.stream.Collectors;

import net.hobbyscience.database.Conversion;
import net.hobbyscience.database.ConversionMethod;
import net.hobbyscience.database.exceptions.BadMathExpression;
import net.hobbyscience.database.exceptions.NoConversionFound;
import net.hobbyscience.database.methods.ForDB;
import net.hobbyscience.math.EquationReducer;
import net.hobbyscience.math.Equations;

public class ConversionGraph {
    private static Logger log = Logger.getLogger(ConversionGraph.class.getName());
    
    private Set<Conversion> initialConversions;

    public ConversionGraph(Set<Conversion> conversions) {
        this.initialConversions = conversions;
    }

    private Set<Conversion> expandConversions(Set<String> unitClasses,
            Set<Conversion> conversions) {
        HashSet<Conversion> newConversions = new HashSet<>();        
        List<Unit> units = conversions.stream().map( Conversion::getFrom ).distinct().collect( Collectors.toList() );
        units.addAll( conversions.stream().map( Conversion::getTo ).distinct().collect( Collectors.toList() ) );
        units = units.stream()
                     .sorted( (l,r) -> l.getName().compareTo(r.getName()))
                     .distinct()
                     .collect(Collectors.toList());
        // forward
        var unitChainStr = new StringBuffer(200);
        var unitChain = new ArrayDeque<Conversion>(10);
        units.forEach( u -> log.fine("*"+u+"*"));
        for( Unit from: units ){
            for( Unit to: units ){                
                if( from.equals(to) ) continue;

                
                log.fine(() -> String.format("Finding conversion from %s to %s",from,to));
                var steps = new ArrayDeque<>(findConversion(from,to,conversions));
                if( steps.isEmpty() ){
                    throw new NoConversionFound("Unable to find conversion from " + from + " to " + to);
                }
                unitChain.clear();
                unitChainStr.setLength(0);

                log.fine("Reducing/combining conversion steps");
                var conversion = steps.pollLast();                
                unitChain.push(conversion);
                String postfix = conversion.getMethod().getPostfix();
                Conversion step = null;
                while ((step = steps.pollLast()) != null) {
                    unitChain.push(step);
                    postfix = Equations.combine(postfix, step.getMethod().getPostfix());
                }

                step = unitChain.pollFirst();
                unitChainStr.append(String.format("%s -> %s",step.getFrom().getAbbreviation(),step.getTo().getAbbreviation()));
                while ((step = unitChain.pollFirst()) != null) {
                    unitChainStr.append(String.format(" -> %s",step.getTo().getAbbreviation()));
                }

                try {
                    var reduced = EquationReducer.reduce(postfix);
                    newConversions.add( 
                        new Conversion(
                            from,
                            to,
                            new ForDB(reduced),
                            unitChainStr.toString()
                        )
                    );
                } catch( BadMathExpression bme ) {
                    throw new BadMathExpression(
                        String.format("Unable to handle conversion (%s) for units (%s->%s)",
                                      postfix,
                                      from.getAbbreviation(),
                                      to.getAbbreviation()),bme);
                }
                
                
                
            }
        }        

        return newConversions;
    }

    private class Node {
        private Conversion conversion = null;
        private Set<Node> children = new HashSet<>();
        private int dir;

        public static final int FWD = 0;
        public static final int INV = 1;

        public Node( Conversion conversion, int dir ){
            this.conversion = conversion;
            this.dir = dir;
        }

        public void findConversions( Set<Conversion> conversions){            
            var remaining = conversions.stream().filter( c -> !c.equals(this.conversion)  ).collect(Collectors.toSet());
            
            if( remaining.size() == 0 ) return;        

            remaining.forEach( conv -> {                
                Unit unit = dir == INV ? conversion.getFrom() : conversion.getTo();

                if( conv.getFrom().equals(unit) ){                    
                    children.add( new Node(conv,FWD));
                } else if ( conv.getTo().equals(unit) ){                    
                    children.add( new Node(conv,INV));
                }
            });
            
            children.forEach( child -> {
                var for_next = new HashSet<Conversion>();
                for_next.addAll(remaining);
                child.findConversions(for_next); 
            });
            
        }

        public Optional<Queue<Conversion>> queue( Unit to, Queue<Conversion> queue ){
            Queue<Conversion> q = queue == null ? new LinkedList<Conversion>() : queue;                        
            
            var conv = dir == FWD ? conversion : conversion.getInverse();

            if( conv.getTo().equals(to) ){                
                // we've found our destination
                q.add( conv );
                return Optional.of(q);
            } else if ( !conv.getTo().equals(to) && children.isEmpty() ){                
                return Optional.empty();
            } else {
                
                q.add(conv);
                Set<Queue<Conversion>> queues = new HashSet<>();

                // build paths for each child            
                children.forEach( child -> {
                    Queue<Conversion> tmp = new LinkedList<>();
            
                    tmp.addAll(q);
            
                    var q2 = child.queue(to,tmp);
                    if( q2.isPresent() ){
                        queues.add(q2.get());
                    }                    
                });                
                // return the shortest path
                return Optional.ofNullable(queues.stream().sorted( (l,r) -> {
                    if( l.size() < r.size() ) return -1;
                    else if ( l.size() == r.size() ) return 0;
                    else return 1;
                }).findFirst().orElseGet( () -> null ));

            }                        
        }
    }

    private Queue<Conversion> findConversion(Unit from, Unit to, Set<Conversion> conversions) {                
        Set<Node> roots = new HashSet<>();

        // find the roots
        conversions.forEach( conv -> {
            if( conv.getFrom().equals(from) ){
                roots.add( new Node(conv,Node.FWD) );
            } else if ( conv.getTo().equals(from) ) {
                roots.add( new Node(conv,Node.INV));
            }
        });
        // get all the possible root level conversions
        Set<Conversion> rootConvs = roots.stream()
            .map( rc -> rc.conversion ).collect(Collectors.toSet());
        // find what conversions are left to do
        Set<Conversion> remaining = conversions.stream()
            .filter( c -> !rootConvs.contains(c) ).collect(Collectors.toSet());
        Set<Queue<Conversion> > queues = new HashSet<>();
        // find all possible paths
        roots.forEach( root -> {
            root.findConversions(remaining);
            var steps = root.queue( to, null );
            if( steps.isPresent() ){
                queues.add(steps.get());
            }
        });
        if( queues.isEmpty() ) throw new NoConversionFound("No conversion found from " + from + " to " + to );        
        // got through each path and select the shortest.
        final AtomicInteger shortestLength = new AtomicInteger(-1);
        Comparator<Queue<Conversion>> sorter = (var l, var r) -> {
            if( l.size() < r.size() ) return -1;
            else if ( l.size() == r.size() ) return 0;
            else return 1;
        };
        return queues.stream()
                     .sorted(sorter)
                     // prep for future work to also filter by weight of
                     // size, in-same-unit-family, other?
                     // maybe that should be part of the sorting somehow?
                     .takeWhile(q -> {
                        if (shortestLength.get() == -1) {
                            shortestLength.set(q.size());
                        }
                        return q.size() == shortestLength.get();
                      })
                     .findFirst()
                     .orElse(new ArrayDeque<>());
    }

    public HashSet<Conversion> generateConversions(){
        HashSet<Conversion> retVal = new HashSet<>();
        Set<String> unitClasses = initialConversions.stream().map( c -> c.getFrom().getAbstractParameter() ).distinct().collect(Collectors.toSet());
        for( String unitClass: unitClasses){
            System.out.println ("Expanding unit conversions for unit class " + unitClass);
            Set<Conversion> _conversions = 
                initialConversions.stream()
                            .filter( c -> c.getFrom().getAbstractParameter().equalsIgnoreCase(unitClass) == true )
                            .collect( Collectors.toSet() );                        
            retVal.addAll( expandConversions(unitClasses, _conversions));
        }
        return retVal;
    }
}
