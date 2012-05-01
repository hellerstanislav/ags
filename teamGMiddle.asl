factorial(0,1).
factorial(N,F) :- factorial(N-1,F1) & F = N*F1.

!start.
!printfact5.
+!start : .my_name(Name) & .substring("a",Name,0) <- +side("a").
+!start : .my_name(Name) & .substring("b",Name,0) <- +side("b").


@p1[atomic]
+!printfact5 : .my_name(aMiddle) <- ?factorial(5,F);
				+hodnota_faktorialu(5,F);
				.print("Factorial(5) = ", F).

+hodnota_faktorialu(X,F) <-.print("Ulozeno fact(", X, ")=",F).
@p2[atomic]
+!printfact5  <- .print("Nejsem agentA, nereknu nic").


+step(X) <- !akce1;!akce2;do(skip);do(skip).
+!akce1 : friend(F) & .substring("Slow",F) <- .print("I have a friend: ", F, " and he is a slow type").
+!akce1 : friend(F) & .substring("Fast",F) <- .print("I have a friend: ", F, " and he is a fast type").
+!akce1 : friend(F) & .substring("Middle",F) <- .print("I have a friend: ", F, " and he is a middle type").

+!akce2 <- .my_name(Name);?side(Side);.print("I am: ", Name, " on side: ", Side).
