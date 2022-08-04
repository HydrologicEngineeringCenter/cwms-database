/*
 * Copyright 2022 Michael Neilson
 * Licensed Under MIT License. https://github.com/MikeNeilson/housedb/LICENSE.md
 */

package net.hobbyscience;

import java.util.LinkedList;
import java.util.Queue;
import java.util.Stack;

public class SimpleInfixCalculator {
    public static double calculate( String infix, double input ){
        Queue<String> tokens = new LinkedList<>();
        for(String token: infix.split("\\s+")){
            tokens.add(token);
        }
        Stack<Double> reg = new Stack<>();

        tokens.forEach( token -> {
            switch (token ){
                case "i":{ reg.push(input); break; }                 
                case "*":{
                    double tmp = reg.pop();
                    tmp *= reg.pop();
                    reg.push(tmp);
                    break; 
                }
                case "+":{
                    double tmp = reg.pop();
                    tmp += reg.pop();
                    reg.push(tmp);
                    break;
                }
                case "-":{
                    double l = reg.pop();
                    double r = reg.pop();
                    double tmp = r-l;
                    reg.push(tmp);
                    break;
                }
                case "/":{
                    double l = reg.pop();
                    double r = reg.pop();
                    double tmp = r/l;
                    reg.push(tmp);
                    break;
                }
                case "^":{
                    double power = reg.pop();
                    double base = reg.pop();
                    double tmp = Math.pow(base,power);
                    reg.push(tmp);
                    break;
                }
                default: {
                    reg.push(Double.parseDouble(token));
                    break;
                }                
            }            
        });
        return reg.pop();
    }
}
