unvisited(0,0).
unvisited(0,3).
unvisited(0,6).
unvisited(0,9).
unvisited(0,12).
unvisited(0,15).
unvisited(0,18).
unvisited(0,21).
unvisited(0,24).
unvisited(0,27).
unvisited(0,30).
unvisited(0,33).
unvisited(3,0).
unvisited(3,3).
unvisited(3,6).
unvisited(3,9).
unvisited(3,12).
unvisited(3,15).
unvisited(3,18).
unvisited(3,21).
unvisited(3,24).
unvisited(3,27).
unvisited(3,30).
unvisited(3,33).
unvisited(6,0).
unvisited(6,3).
unvisited(6,6).
unvisited(6,9).
unvisited(6,12).
unvisited(6,15).
unvisited(6,18).
unvisited(6,21).
unvisited(6,24).
unvisited(6,27).
unvisited(6,30).
unvisited(6,33).
unvisited(9,0).
unvisited(9,3).
unvisited(9,6).
unvisited(9,9).
unvisited(9,12).
unvisited(9,15).
unvisited(9,18).
unvisited(9,21).
unvisited(9,24).
unvisited(9,27).
unvisited(9,30).
unvisited(9,33).
unvisited(12,0).
unvisited(12,3).
unvisited(12,6).
unvisited(12,9).
unvisited(12,12).
unvisited(12,15).
unvisited(12,18).
unvisited(12,21).
unvisited(12,24).
unvisited(12,27).
unvisited(12,30).
unvisited(12,33).
unvisited(15,0).
unvisited(15,3).
unvisited(15,6).
unvisited(15,9).
unvisited(15,12).
unvisited(15,15).
unvisited(15,18).
unvisited(15,21).
unvisited(15,24).
unvisited(15,27).
unvisited(15,30).
unvisited(15,33).
unvisited(18,0).
unvisited(18,3).
unvisited(18,6).
unvisited(18,9).
unvisited(18,12).
unvisited(18,15).
unvisited(18,18).
unvisited(18,21).
unvisited(18,24).
unvisited(18,27).
unvisited(18,30).
unvisited(18,33).
unvisited(21,0).
unvisited(21,3).
unvisited(21,6).
unvisited(21,9).
unvisited(21,12).
unvisited(21,15).
unvisited(21,18).
unvisited(21,21).
unvisited(21,24).
unvisited(21,27).
unvisited(21,30).
unvisited(21,33).
unvisited(24,0).
unvisited(24,3).
unvisited(24,6).
unvisited(24,9).
unvisited(24,12).
unvisited(24,15).
unvisited(24,18).
unvisited(24,21).
unvisited(24,24).
unvisited(24,27).
unvisited(24,30).
unvisited(24,33).
unvisited(27,0).
unvisited(27,3).
unvisited(27,6).
unvisited(27,9).
unvisited(27,12).
unvisited(27,15).
unvisited(27,18).
unvisited(27,21).
unvisited(27,24).
unvisited(27,27).
unvisited(27,30).
unvisited(27,33).
unvisited(30,0).
unvisited(30,3).
unvisited(30,6).
unvisited(30,9).
unvisited(30,12).
unvisited(30,15).
unvisited(30,18).
unvisited(30,21).
unvisited(30,24).
unvisited(30,27).
unvisited(30,30).
unvisited(30,33).
unvisited(33,0).
unvisited(33,3).
unvisited(33,6).
unvisited(33,9).
unvisited(33,12).
unvisited(33,15).
unvisited(33,18).
unvisited(33,21).
unvisited(33,24).
unvisited(33,27).
unvisited(33,30).
unvisited(33,33).

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
is(X,X).
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

// GOTO PLAN - nejdrive jede k depotu, pak krouzi kolem nej
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

distance(MyX,MyY,X,Y,Dist) :- distance_x_line(MyX, X, Y, Dist_Y) &
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
    //.print(Keeper) &
    pos(PosX,PosY) & depot(DepX,DepY) & 
	first(H,Xtarget) & second(H,Ytarget) &
    distance(PosX,PosY,Xtarget,Ytarget,PosDist) &
	distance(DepX,DepY,Xtarget,Ytarget,DepDist) &
	Dist = (PosDist + 2*DepDist) &
	Dist < MinDist &
	min_distance_worker(T,Dist,[H],UnvisitedMinDistList).

min_distance_worker([H|T],MinDist,Keeper,UnvisitedMinDistList) :-
    //.print(Keeper) &
    pos(PosX,PosY) & depot(DepX,DepY) &
	first(H,Xtarget) & second(H,Ytarget) &
    distance(PosX,PosY,Xtarget,Ytarget,PosDist) &
	distance(DepX,DepY,Xtarget,Ytarget,DepDist) &
	Dist = (PosDist + 2*DepDist) &
	is(Dist,MinDist) & .concat([H],Keeper,NewKeeper) & 
	min_distance_worker(T,Dist,NewKeeper,UnvisitedMinDistList).

min_distance_worker([H|T],MinDist,Keeper,UnvisitedMinDistList) :-
    //.print(Keeper) &
    pos(PosX,PosY) & depot(DepX,DepY) &
	first(H,Xtarget) & second(H,Ytarget) &
    distance(PosX,PosY,Xtarget,Ytarget,PosDist) &
	distance(DepX,DepY,Xtarget,Ytarget,DepDist) &
	Dist = (PosDist + 2*DepDist) &
	Dist > MinDist &
	min_distance_worker(T,MinDist,Keeper,UnvisitedMinDistList).


// pomocny rekurzivni srotovac pro naplanovani vsech bodu z listu UnvisitedMinDistList
+!plan_nearest_unvisited_worker([]) <- true.
+!plan_nearest_unvisited_worker([H|T])
    <- ?first(H,X); ?second(H,Y);
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
//+!add_obstacles : obstacle(X,Y)
//    <- +known_obstacle(X,Y); -unvisited(X,Y).
+!add_obstacles
    <- .findall([X,Y], obstacle(X,Y), VisibleObstacles);
	    !add_obstacles_worker(VisibleObstacles).

+!add_obstacles_worker([]) <- true.
+!add_obstacles_worker([H|T])
    <- ?first(H,X); ?second(H,Y); // ziskani souradnic
	   +known_obstacle(X,Y); -unvisited(X,Y); // zapsani prekazky do db
	   !add_obstacles_worker(T).

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
	   // pridej vsechny prekazky o kterych vis toto kolo
	   !add_obstacles;
	   // pokud nemas prazdny plan, tak jedem
	   if(not empty_goto_plan) {
	       // ziskani prvni pozice z planu, kam se ma jet
	       ?get_first_position(X,Y);
		   
		   // Pokud je tam prekazka (tzn pozice byla naplanovana pred tim, nez
		   // jsem uvidel, ze tam je prekazka), tak tam nejedu a pokracuju dal.
		   // Pokud uz na naplanovane pozici stojim, tak samozrejme jedu na dalsi
		   if (pos(X,Y) | known_obstacle(X,Y)) {
		       // odstraneni prvniho prvku v goto planu
		       !pop_first_position;
			   // rekurzivne se zavola sam na sebe (jede na dalsi prvek v goto planu)
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
    <- !do_step.


