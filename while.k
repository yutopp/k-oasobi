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
                     | "if" BExp "then" Stmt "else" Stmt    [strict(1)]
                     | "while" BExp "do" Stmt
                     | "begin" Dv Dp Stmt "end"
                     | "call" Id
                     | Id ":=" AExp     [strict(2)]
                     > Stmt ";" Stmt    [left, seqstrict]
                     > "(" Stmt ")"     [bracket]

       syntax VarDecl ::= "var" Id ":=" AExp ";"    [strict(2)]
       syntax Dv ::= List{VarDecl, ""}

       syntax ProcDecl ::= "proc" Id "is" Stmt ";"
       syntax Dp ::= List{ProcDecl, ""}
endmodule

module WHILE
       import WHILE-SYNTAX


       syntax KResult ::= Int | Bool


       configuration <T>
           <k color="green"> $PGM:Stmt </k>

           <envv color="blue"> .Map </envv>
           <store color="red"> .Map </store>

           <envp color="yellow"> .Map </envp>

           <nextLoc color="gray"> 0 </nextLoc>
       </T>


       // AExp
       rule <k> X:Id => I ... </k>
            <envv>... X |-> N ...</envv>
            <store>... N |-> I ...</store>

       rule A1 * A2 => A1 *Int A2
       rule A1 + A2 => A1 +Int A2
       rule A1 - A2 => A1 -Int A2


       // BExp
       rule ! B:Bool => notBool B
       rule A1 = A2 => A1 ==Int A2


       // Stmt
       rule <k> (X := I:Int) => . ... </k>
            <envv>... X |-> Loc ...</envv>
            <store>... Loc |-> (_ => I) ...</store>     [assignment]    // update

       rule <k> (X := I:Int) => . ... </k>
            <envv> M:Map => M (X |-> Loc) </envv>
            <store> Sto:Map => Sto (Loc |-> I) </store>
            <nextLoc> Loc:Int => (Loc +Int 1) </nextLoc>
         when notBool(X in keys(M)) [assignment]    // init

       rule skip => .

       rule if  true then S:Stmt else _ => S
       rule if false then _ else S:Stmt => S

       rule while B:BExp do S:Stmt => if B then (S; while B do S) else skip      [structural]

       syntax KItem ::= envv(K) | envp(K)
       rule <k> begin Dvs:Dv Dps:Dp S:Stmt end => Dvs ~> Dps ~> S ~> envv(CurEnvV) ~> envp(CurEnvP) ... </k>
            <envv> CurEnvV:Map </envv>
            <envp> CurEnvP:Map </envp>  [structural]
       rule <k> envv(CurEnvV) => . ... </k> <envv> _ => CurEnvV </envv>   [structural]
       rule <k> envp(CurEnvP) => . ... </k> <envp> _ => CurEnvP </envp>   [structural]

       // call rec
       rule <k> call P:Id => PTup ... </k>
            <envp> ... P |-> PTup ... </envp>  [structural]
       rule <k> ptuple(P, S, EnvV, EnvP) => S ~> envv(CurEnvV) ~> envp(CurEnvP) ... </k>
            <envv> CurEnvV:Map => EnvV </envv>
            <envp> CurEnvP:Map => EnvP[P <- ptuple(P, S, EnvV, EnvP)] </envp>  [structural]

       rule S1:Stmt ; S2:Stmt => S1 ~> S2   [structural]


       // vardecl
       rule D:VarDecl Ds:Dv => D ~> Ds    [structural]
       rule .Dv => .                      [structural]

       rule <k> var X := I:Int ; => . ... </k>
            <envv> M:Map => M[X <- Loc] </envv>
            <store> Sto:Map => Sto (Loc |-> I) </store>
            <nextLoc> Loc:Int => (Loc +Int 1) </nextLoc>


       // procdecl
       rule P:ProcDecl Ps:Dp => P ~> Ps     [structural]
       rule .Dp => .                        [structural]

       syntax KItem ::= ptuple(K, Stmt, Map, Map)
       rule <k> proc P is S:Stmt ; => . ... </k>
            <envv> EnvV:Map </envv>
            <envp> EnvP:Map => EnvP[P <- ptuple(P, S, EnvV, EnvP)] </envp>
endmodule