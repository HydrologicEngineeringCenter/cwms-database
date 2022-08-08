package net.hobbyscience.math;

import java.util.ArrayDeque;
import java.util.Deque;

import jmc.cas.*;
import net.objecthunter.exp4j.tokenizer.OperatorToken;
import net.objecthunter.exp4j.tokenizer.Token;

public class Algebra {
    private static String reducePostfix(String postfix) {
        var tokens = Equations.stringToTokens(postfix);
        OperatorToken currentOp = null;
        Deque<Token> reg = new ArrayDeque<>(2);
        Operable operationTree = null;
        Token token = null;
        while ((token = tokens.pollLast()) != null) {

        }


        return null;
    }
}
