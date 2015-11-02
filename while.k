// ref. Semantics with Applications: An Appetizer

module WHILE-SYNTAX
       syntax AExp ::= Int | Id
                     > AExp "*" AExp    [left, seqstrict]
                     > AExp "+" AExp    [left, seqstrict]
                     | AExp "-" AExp    [left, seqstrict]
                     > "(" AExp ")"     [bracket]

       syntax BExp ::= Bool
                     | "!" BExp         [strict]
                     > AExp "=" AExp    [seqstrict]
                     > "(" BExp ")"     [bracket]

       syntax Stmt ::= "skip"
                     | "if" BExp "then" Stmt "else" Stmt  [strict(1)]
                     | "while" BExp "do" Stmt
                     | Id ":=" AExp     [strict(2)]
                     > Stmt ";" Stmt    [left, seqstrict]
                     > "(" Stmt ")"     [bracket]
endmodule

module WHILE
       import WHILE-SYNTAX


       syntax KResult ::= Int | Bool


       configuration <T>
           <k color="green"> $PGM:Stmt </k>

           <env color="blue"> .Map </env>
           <store color="red"> .Map </store>

           <nextLoc color="gray"> 0 </nextLoc>
       </T>


       // AExp
       rule <k> X:Id => I ... </k>
            <env>... X |-> N ...</env>
            <store>... N |-> I ...</store>

       rule A1 * A2 => A1 *Int A2
       rule A1 + A2 => A1 +Int A2
       rule A1 - A2 => A1 -Int A2


       // BExp
       rule ! B:Bool => notBool B
       rule A1 = A2 => A1 ==Int A2


       // Stmt
       rule <k> (X := I:Int) => . ... </k>
            <env>... X |-> N ...</env>
            <store>... N |-> (_ => I) ...</store> [assignment]

       rule <k> (X := I:Int) => . ... </k>
            <env> M:Map => M (X |-> N) </env>
            <store> Sto:Map => Sto (N |-> I) </store>
            <nextLoc> N:Int => (N +Int 1) </nextLoc>
         when notBool(X in keys(M)) [assignment]

       rule skip => .

       rule if  true then S:Stmt else _ => S
       rule if false then _ else S:Stmt => S

       rule while B:BExp do S:Stmt => if B then (S; while B do S) else skip      [structural]

       rule S1:Stmt ; S2:Stmt => S1 ~> S2   [structual]
endmodule