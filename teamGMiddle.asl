
unvisited(29,29).
unvisited(20,15).
unvisited(27,16).


border(X,-1).
border(-1,Y).
border(X,Y) :- grid_size(X,_).
border(X,Y) :- grid_size(_,Y).

abs(X, X) :- X > -1.
abs(X, AbsX) :- AbsX = -X.

possible(right) :- pos(MyX, MyY) & not (obstacle(MyX+1, MyY) | border(MyX+1, MyY)).
possible(up) :- pos(MyX, MyY) & not (obstacle(MyX, MyY-1) | border(MyX, MyY-1)).
possible(left) :- pos(MyX, MyY) & not (obstacle(MyX-1, MyY) | border(MyX-1, MyY)).
possible(down) :- pos(MyX, MyY) & not (obstacle(MyX, MyY+1) | border(MyX, MyY+1)).

complement_x_dir(left, right).
complement_x_dir(right, left).
complement_x_dir(none, left).
complement_y_dir(up, down).
complement_y_dir(down, up).
complement_y_dir(none, down).

is_x_dir(left).
is_x_dir(right).
is_y_dir(up).
is_y_dir(down).

get_x_dir(MyX, TargetX, right) :- TargetX > MyX.
get_x_dir(MyX, TargetX, left) :- TargetX < MyX.
get_x_dir(MyX, TargetX, none) :- TargetX == MyX.
get_y_dir(MyY, TargetY, up) :- TargetY < MyY.
get_y_dir(MyY, TargetY, down) :- TargetY > MyY.
get_y_dir(MyY, TargetY, none) :- TargetY == MyY.

//primitiva
first([H|T], H).
second([H|T], HH) :- first(T, HH).
// pridani prvku na zacatek seznamu
prepend(H,[], [H]).
prepend(H,L, [H|L]).
// test, zda X lezi v intervalu (From,To)
between(X, From, To) :- From < To & X > From & X < To.
between(X, From, To) :- From > To & X < From & X > To.
// vzdalenost mezi dvema body v 1D
euler_dist(A,B,Dist) :- A > B & Dist = A - B.
euler_dist(A,B,Dist) :- A < B & Dist = B - A.
euler_dist(A,B,0) :- A=B.

// GOTO PLAN //
//goto_plan([[2,2],[33,14],[0,20],[15,14]]).
goto_plan([[X,Y]]) :- depot(X,Y). // nejdrive jed k depotu
empty_goto_plan :- goto_plan([]).
get_first_position(X,Y) :- goto_plan([H|T]) & first(H, X) & second(H, Y).

// Zjistovani, jestli mezi dvema body na jedne souradnici lezi prekazka
obstacle_on_x_path(X1,X2,Y) :- known_obstacle(Xobs, Y) & between(Xobs, X1, X2).
obstacle_on_y_path(Y1,Y2,X) :-known_obstacle(X, Yobs) & between(Yobs, Y1, Y2).

// zjistovani vzdalenosti mezi dvema body na stejne souradnici
distance_x_line(X1, X2, Y, Dist) :- obstacle_on_x_path(X1,X2,Y) & 
                                    euler_dist(X1,X2,D) & 
								    Dist = D + 3.
distance_x_line(X1, X2, Y, Dist) :- euler_dist(X1,X2,Dist).
distance_y_line(Y1, Y2, X, Dist) :- obstacle_on_y_path(Y1,Y2,X) & 
                                    euler_dist(Y1,Y2,D) & 
									Dist = D + 3.
distance_y_line(Y1, Y2, X, Dist) :- euler_dist(Y1,Y2,Dist).



// zjistovani vzdalenosti mezi dvema libovolnymi body
//distance(X1,Y1,X2,Y2,0).

distance(MyX,MyY,X,Y,Dist) :- pos(MyX,MyY) &
                              distance_x_line(MyX, X, Y, Dist_Y) &
							  distance_x_line(MyX, X, MyY, Dist_MyY) &
							  distance_y_line(MyY, Y, X, Dist_X) &
							  distance_y_line(MyY, Y, MyX, Dist_MyX) &
							  A = Dist_MyX + Dist_Y &
							  B = Dist_MyY + Dist_X &
							  .min([A,B],Dist).

// predikat pro zjisteni, jestli bod (X,Y) lezi na hraci plose
on_board(X,Y) :- grid_size(GX,GY) & between(X,-1,GX+1) & between(Y, -1, GY+1).


// zjisteni vsech bodu, ktere jsou aktualne od agenta nejblize
min_distance(Unvisited,UnvisitedMinDistList) :-
    min_distance_worker(Unvisited,1000,[],UnvisitedMinDistList).

min_distance_worker([],_,K,K).

min_distance_worker([H|T],MinDist,Keeper,UnvisitedMinDistList) :-
    pos(PosX,PosY) & first(H,Xtarget) & second(H,Ytarget) &
    distance(PosX,PosY,Xtarget,Ytarget,Dist) &
	Dist < MinDist &
	min_distance_worker(T,Dist,[H],UnvisitedMinDistList).

min_distance_worker([H|T],MinDist,Keeper,UnvisitedMinDistList) :-
    pos(PosX,PosY) & first(H,Xtarget) & second(H,Ytarget) &
    distance(PosX,PosY,Xtarget,Ytarget,Dist) &
	Dist = MinDist & .concat([H],Keeper,NewKeeper) & 
	min_distance_worker(T,Dist,NewKeeper,UnvisitedMinDistList).

min_distance_worker([H|T],MinDist,Keeper,UnvisitedMinDistList) :-
    pos(PosX,PosY) & first(H,Xtarget) & second(H,Ytarget) &
    distance(PosX,PosY,Xtarget,Ytarget,Dist) &
	Dist > MinDist &
	min_distance_worker(T,MinDist,Keeper,UnvisitedMinDistList).


// pomocny rekurzivni srotovac pro naplanovani vsech bodu z listu UnvisitedMinDistList
+!plan_nearest_unvisited_worker([]) <- true.	   
+!plan_nearest_unvisited_worker([H|T])
    <- ?first(H,X);?second(H,Y);
	   !plan_best_path(X,Y);
	   !plan_nearest_unvisited_worker(T).
	   
// prida do planu nejblizsi nenavstivene body na mape
+!plan_nearest_unvisited
    <- .findall([X,Y], unvisited(X,Y), Unvisited);
	   ?min_distance(Unvisited,UnvisitedMinDistList);
	   !plan_nearest_unvisited_worker(UnvisitedMinDistList).
	   
// prida bod na zacatek planu
+!prepend_to_goto_plan(X,Y)
    <- ?goto_plan(G);
	   ?prepend([X,Y],G,GG);
	   -goto_plan(_);
	   +goto_plan(GG).
	
// naplanuje do goto planu nejlepsi moznou cestu do bodu A[X,Y]
+!plan_best_path(X,Y) : pos(MyX, MyY)
    <- ?distance_x_line(MyX, X, Y, Dist_Y);
	   ?distance_x_line(MyX, X, MyY, Dist_MyY);
	   ?distance_y_line(MyY, Y, X, Dist_X);
	   ?distance_y_line(MyY, Y, MyX, Dist_MyX);
	   // naplanuju cestu do cile
	   !prepend_to_goto_plan(X,Y);
	   // pokud je cesta po y a pak po x mensi
	   if ((Dist_MyX + Dist_Y) < (Dist_MyY + Dist_X)) {
		   // jdeme z (MyX,MyY) do (MyX,Y)
	       !prepend_to_goto_plan(MyX,Y);
	   }
	   else { // jinak je cesta po x a pak po y mensi
		   // jdeme z (MyX,MyY) do (X,MyY)
	       !prepend_to_goto_plan(X,MyY);
	   }.

// pridani vsech viditelnych prekazek do databaze znalosti agenta
+!add_obstacles : obstacle(X,Y)
    <- +known_obstacle(X,Y); -unvisited(X,Y).
+!add_obstacles <- true.

// odstrani prvni prvek z goto planu
+!pop_first_position
    <- ?goto_plan([H|T]);
	   -goto_plan(_);
	   +goto_plan(T).

+!change_complement_x_dir
    <- ?complement_x_dir(none, X);
	   ?complement_x_dir(X, CompX);
	   -complement_x_dir(none, _);
	   +complement_x_dir(none, CompX).

+!change_complement_y_dir
    <- ?complement_y_dir(none, Y);
	   ?complement_y_dir(Y, CompY);
	   -complement_y_dir(none, _);
	   +complement_y_dir(none, CompY).

	   
// zruseni faktu, ze obchazim prekazku
+!reset_solving_obstacle <- -solving_obstacle(_,_).

// pokud uz tam jsi, nikam nechod
+!goto(X,Y) : pos(X,Y) <- true.

// obchazim prekazku
+!goto(X,Y) : solving_obstacle(TargetDir, SolvingDir)
    <- if (possible(TargetDir)) {
	       !reset_solving_obstacle;
	       do(TargetDir)
	   }
	   else {
	       if (possible(SolvingDir)) {
		       do(SolvingDir)
		   }
	       else {
			   if (is_x_dir(TargetDir)) {
			       ?complement_x_dir(TargetDir, CompTargetDir);
			   }
			   else {
			       ?complement_y_dir(TargetDir, CompTargetDir);
			   }
               if (possible(CompTargetDir)) {
				   !reset_solving_obstacle;
				   +solving_obstacle(SolvingDir, CompTargetDir);
				   do(CompTargetDir)
			   }
			   else {
				   if (is_x_dir(SolvingDir)) {
					   ?complement_x_dir(SolvingDir, CompSolvingDir);
				   }
				   else {
					   ?complement_y_dir(SolvingDir, CompSolvingDir);
				   }
				   if (possible(CompSolvingDir)) {
					   !reset_solving_obstacle;
					   +solving_obstacle(CompTargetDir, CompSolvingDir);
					   do(CompSolvingDir)
				   }
			   }
		   }
	   }.

// jdu normalne za cilem po x-ove ose
+!goto(X,Y) : pos(MyX, MyY) & get_x_dir(MyX, X, Xdir) & not (Xdir == none)
    <- if (possible(Xdir)) {
	       do(Xdir)
	   }
	   else {
	       ?get_y_dir(MyY, Y, Ydir);
	       if (possible(Ydir)) {
		       +solving_obstacle(Xdir,Ydir);
		       do(Ydir)
		   }
		   else {
		       ?complement_y_dir(Ydir, CompYdir);
			   !change_complement_y_dir;
			   if (possible(CompYdir)) {
			       +solving_obstacle(Xdir, CompYdir);
				   do(CompYdir)
			   }
			   else {
			       ?complement_x_dir(Xdir, CompXdir);
				   !change_complement_x_dir;
				   +solving_obstacle(Xdir, CompXdir);
				   do(CompXdir)
			   }
		   }
	   }.

+!goto(X,Y) : pos(MyX, MyY) & get_y_dir(MyY, Y, Ydir) & not (Ydir == none)
    <- if (possible(Ydir)) {
	       do(Ydir)
	   }
	   else {
	       ?get_x_dir(MyX, X, Xdir);
	       if (possible(Xdir)) {
		       +solving_obstacle(Ydir, Xdir);
		       do(Xdir)
		   }
		   else {
		       ?complement_x_dir(Xdir, CompXdir);
			   !change_complement_x_dir;
			   if (possible(CompXdir)) {
			       +solving_obstacle(Ydir, CompXdir);
				   do(CompXdir)
			   }
			   else {
			       ?complement_y_dir(Ydir, CompYdir);
				   !change_complement_y_dir;
				   +solving_obstacle(Ydir, CompYdir);
				   do(CompYdir)
			   }
		   }
	   }.

// udela jeden krok k prvni naplanovane pozici
// pokud nejsou zadne naplanovane pozice, jde tam, kde jeste nebyl
+!goto_next_position : pos(MyX,MyY)
    <- // zaznamenam, si, kde jsem
	   -unvisited(MyX,MyY);
	   if(not empty_goto_plan) {
	       ?get_first_position(X,Y);
		   // pokud jsem uz na te pozici, tak jedu dal
		   if (pos(X,Y)) {
		       !pop_first_position;
			   !goto_next_position
		   }
		   else {
		       !goto(X,Y)
		   }
	   }
	   else {
	       !plan_nearest_unvisited;
		   !goto_next_position
	   }.

// dela kroky dokud v danem kole muze
+!do_step : moves_left(M) & (M > 1) 
      <- !goto_next_position;
		 !do_step.

+!do_step : moves_left(M) & M == 1
      <- !goto_next_position.

+step(X)
    <- !add_obstacles;
	   !do_step.


