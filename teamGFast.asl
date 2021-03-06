/* File: teamGMiddle.asl
 * Authors: Daniela Duricekova, xduric00@stud.fit.vutbr.cz
 *			Stanislav Heller, xhelle03@stud.fit.vutbr.cz
 *			Andrej Trnkoci, xtrnko00@stud.fit.vutbr.cz
 * Description: This file implements behaviour of the fast agent.
 */

get_fast_name(aFast) :- friend(aFast).
get_fast_name(bFast) :- friend(bFast). 
get_middle_name(aMiddle) :- friend(aMiddle).
get_middle_name(bMiddle) :- friend(bMiddle).
get_slow_name(aSlow) :- friend(aSlow).
get_slow_name(bSlow) :- friend(bSlow). 
 
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

complement_dir(left, right).
complement_dir(right, left).
complement_dir(up, down).
complement_dir(down, up).

solving_pos_score(X,Y,0) :- .count(solving_position(X,Y,_),0).
solving_pos_score(X,Y,Score) :- solving_position(X,Y,Score).

solving_dir_score(right,Score) :- pos(X,Y) & possible(right) & solving_pos_score(X+1,Y,Score).
solving_dir_score(right,999) :- pos(X,Y) & possible(right).
solving_dir_score(right,1000).
solving_dir_score(up,Score) :- pos(X,Y) & possible(up) & solving_pos_score(X,Y-1,Score).
solving_dir_score(up,999) :- pos(X,Y) & possible(up).
solving_dir_score(up,1000).
solving_dir_score(left,Score) :- pos(X,Y) & possible(left) & solving_pos_score(X-1,Y,Score).
solving_dir_score(left,999) :- pos(X,Y) & possible(left).
solving_dir_score(left,1000).
solving_dir_score(down,Score) :- pos(X,Y) & possible(down) & solving_pos_score(X,Y+1,Score).
solving_dir_score(down,999) :- pos(X,Y) & possible(down).
solving_dir_score(down,1000).

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
//goto_plan([[9,26],[11,15]]).
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

// stav agenta
// searching | harvesting | going_to_depot
state(searching).

// zjistovani vzdalenosti mezi dvema libovolnymi body
distance(MyX,MyY,X,Y,Dist) :- distance_x_line(MyX, X, Y, Dist_Y) &
							  distance_x_line(MyX, X, MyY, Dist_MyY) &
							  distance_y_line(MyY, Y, X, Dist_X) &
							  distance_y_line(MyY, Y, MyX, Dist_MyX) &
							  A = Dist_MyX + Dist_Y &
							  B = Dist_MyY + Dist_X &
							  .min([A,B],Dist).

// predikat pro zjisteni, jestli bod (X,Y) lezi na hraci plose
//on_board(X,Y) :- grid_size(GX,GY) & between(X,-1,GX+1) & between(Y, -1, GY+1).
on_board(X,Y) :- grid_size(GX,GY) & X < GX & Y < GY.

// vypocet funkce agregovane vzdalenosti od mista, kde agent je a od depotu
aggregated_distance(PosDist, DepDist, Dist) :- DepDist > 32 & Dist = (PosDist + 1.6*DepDist).
aggregated_distance(PosDist, DepDist, Dist) :- DepDist < 33 & Dist = (PosDist + 2.1*DepDist).

// zjisteni vsech bodu, ktere jsou aktualne od agenta nejblize
min_distance(Unvisited,UnvisitedMinDistList) :-
    min_distance_worker(Unvisited,1001,[],UnvisitedMinDistList).

min_distance_worker([],_,K,K).

min_distance_worker([H|T],MinDist,Keeper,UnvisitedMinDistList) :-
    pos(PosX,PosY) &
	first(H,Xtarget) & second(H,Ytarget) &
    distance(PosX,PosY,Xtarget,Ytarget,PosDist) &
	PosDist < MinDist &
	min_distance_worker(T,PosDist,[H],UnvisitedMinDistList).

min_distance_worker([_|T],MinDist,Keeper,UnvisitedMinDistList) :- 	
	min_distance_worker(T,MinDist,Keeper,UnvisitedMinDistList).
	
// vsechna mista na mape uz byla navstivena
all_visited :- .count(unvisited(X,Y),0).

// vygeneruje na zacatku vsechny nenavstivene body, ktere je nutne navstivit.
// pravdepodobne budem generovat 3x3 nebo 2x2 sit
+!generate_unvisited : grid_size(GX,GY)
    <- for ( .range(X,0,GX-1) ) {
	       if (((X mod 2) == 0) | (X == GX-1)) {
	           for ( .range(Y,0,GY-1) ) {
		           if (((Y mod 2) == 0) | (Y == GY-1)) { +unvisited(X,Y) }
		       }
		   }
       }.

////////////////////////////////////////////////////////////////////////////////
// PLANY PRO PRIDAVANI A ODSTRANOVANI PREDSTAV AGENTA O OKOLI (prekazky, suroviny) 
////////////////////////////////////////////////////////////////////////////////

// TODO: ROZESILANI ZNALOSTI OSTATNIM AGENTUM!

// pridani vsech viditelnych prekazek do databaze znalosti agenta
+!register_obstacles
    <- .count(known_obstacle(A,B), ObsCount);
	   if (ObsCount > 25) {
	       // SPEEDUP!
	       .abolish(known_obstacle(_,_));
	   }
	   .findall([X,Y], obstacle(X,Y), VisibleObstacles);
	   !register_obstacles_worker(VisibleObstacles).

+!register_obstacles_worker([]) <- true.
+!register_obstacles_worker([H|T])
    <- ?first(H,X); ?second(H,Y); // ziskani souradnic
	   +known_obstacle(X,Y); -unvisited(X,Y); // zapsani prekazky do db
	   ?get_middle_name(MiddleName);
	   .send(MiddleName, achieve, add_known_obstacle(X, Y));
	   ?get_slow_name(SlowName);
	   .send(SlowName, achieve, add_known_obstacle(X, Y));
	   !register_obstacles_worker(T).

// pridavani zlata
+!register_gold
    <- .findall([X,Y], gold(X,Y), VisibleGold);
	   for ( .member(H,VisibleGold) ) {
	       ?first(H,X); ?second(H,Y);
           if (not not_gold(X,Y)) {
		   		+known_gold(X,Y);
				?get_middle_name(MiddleName);
				.send(MiddleName, achieve, treasureFound(X, Y))
		   }	       
       }.

// pridavani dreva do databaze
+!register_wood
    <- .findall([X,Y], wood(X,Y), VisibleWood);
	   for ( .member(H,VisibleWood) ) {
	       ?first(H,X); ?second(H,Y);
		   if (not not_wood(X,Y)) {
           		+known_wood(X,Y);
				?get_middle_name(MiddleName);
				.send(MiddleName, achieve, treasureFound(X, Y))
		   }
       }.

+!register_visited : pos(X,Y)
    <- -unvisited(X,Y); -unvisited(X-1,Y); -unvisited(X+1,Y);
	    -unvisited(X,Y-1); -unvisited(X,Y+1).
		
////////////////////////////////////////////////////////////////////////////////
// PLANOVANI TRAS (pruzkum, tezba)
////////////////////////////////////////////////////////////////////////////////

// odstrani prvni prvek z goto planu
+!pop_first_position
    <- ?goto_plan([H|T]);
	   -goto_plan(_);
	   +goto_plan(T).

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
	   // pokud uz neni tento bod naplanovan na zacatku, tak ho naplanuje
	   if (not get_first_position(X,Y)) {
	       ?prepend([X,Y],G,GG);
	       -goto_plan(_);
	       +goto_plan(GG)
	   }.

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
		   // jdeme z (MyX,MyY) do (MyX,Y) pokud tam je nejaka vzdalenost
		   if (not is(MyY,Y) & not is(MyX,X)) {
	           !prepend_to_goto_plan(MyX,Y);
		   }
	   }
	   else { // jinak je cesta po x a pak po y mensi
		   // jdeme z (MyX,MyY) do (X,MyY)
		   if ((not is(MyX,X)) & (not is(MyY,Y))) {
		       // pokud jsou cesty stejne dlouhe
		       if (is((Dist_MyX + Dist_Y),(Dist_MyY + Dist_X))) {
			       if (unvisited(X,MyY)) {
				       !prepend_to_goto_plan(X,MyY);
				   }
				   else {
				       !prepend_to_goto_plan(MyX,Y);
				   }
			   }
			   else {
	               !prepend_to_goto_plan(X,MyY);
			   }
		   }
	   }.

// naplanuje trasu na nejblizsi zlato
// TODO i drevo
+!plan_harvesting
    <- .findall([X,Y], known_gold(X,Y), Gold);
	   ?min_distance(Gold,MinDistGold);
	   for ( .member(H,MinDistGold) ) {
           ?first(H,X); ?second(H,Y);
		   !plan_best_path(X,Y);
	   }.


////////////////////////////////////////////////////////////////////////////////
// POHYB AGENTA - plany pro pohyb a obchazeni prekazek
////////////////////////////////////////////////////////////////////////////////
// pomocny plan pro zmenu smeru, kudy priste agent bude prekazku obchazet
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

// ulozeni kolikrat jsem byl na danem policku pri obchazeni prekazky
// timto mechanismem se snazi agent vyhnout se cyklum v bludisti
+!update_solving_position : pos(PosX, PosY) 
    <- if(solving_position(PosX,PosY,_)) {
	       ?solving_position(PosX,PosY,C);
		   -solving_position(PosX,PosY,_);
		   +solving_position(PosX,PosY,C+1);
	   }
	   else {
	       +solving_position(PosX,PosY,1)
	   }.

// vybere optimalni smer pro obejiti prekazky. Zalozeno na principu
// skore kazdeho pole, ktere se pocita z toho, kolikrat na danem poli pri
// obchazeni dane prekazky byl. Timto se vyhneme problemu bludiste.
+!choose_optimal_solving_dir : solving_obstacle(TargetDir, SolvingDir)
    <- ?solving_dir_score(TargetDir, TargetScore);
	   ?solving_dir_score(SolvingDir, SolvingScore);
	   ?complement_dir(TargetDir, CompTargetDir);
	   ?solving_dir_score(CompTargetDir, CompTargetScore);
	   ?complement_dir(SolvingDir, CompSolvingDir);
	   ?solving_dir_score(CompSolvingDir, CompSolvingScore);
	   // vybere minimalni skore == nejlepsi cesta
	   .min([TargetScore, SolvingScore, CompTargetScore, CompSolvingScore], M);
	   if (is(M, TargetScore)) {
	       +solving_dir(TargetDir)
	   } else { if (is(M, SolvingScore)) {
	       +solving_dir(SolvingDir);
	   } else { if (is(M, CompTargetScore)) {
	       +solving_dir(CompTargetDir)
	   } else { if (is(M, CompSolvingScore)) {
	       +solving_dir(CompSolvingDir)
	   }}}}.
	   
// pokud uz tam jsi, nikam nechod
+!goto(X,Y) : pos(X,Y) <- true.

// If agent bypasses an obstacle around him.
+!goto(X,Y) : pos(MyX, MyY) & not possible(up) & not possible(down) & not possible(right)
	<-  -unvisited(MyX, MyY);
		+known_obstacle(MyX, MyY);
		+obstacle(MyX, MyY);
		do(left).
+!goto(X,Y) : pos(MyX, MyY) & not possible(up) & not possible(down) & not possible(left)
	<-  -unvisited(MyX, MyY);
		+known_obstacle(MyX, MyY);
		+obstacle(MyX, MyY);
		do(right).
+!goto(X,Y) : pos(MyX, MyY) & not possible(up) & not possible(left) & not possible(right)
	<-  -unvisited(MyX, MyY);
		+known_obstacle(MyX, MyY);
		+obstacle(MyX, MyY);
		do(down).
+!goto(X,Y) : pos(MyX, MyY) & not possible(down) & not possible(left) & not possible(right)
	<-  -unvisited(MyX, MyY);
		+known_obstacle(MyX, MyY);
		+obstacle(MyX, MyY);
		do(up).

// obchazim prekazku
+!goto(X,Y) : solving_obstacle(TargetDir, SolvingDir) 
    <- // pridani bodu do databaze solving_position
	   //.print("SOLVING OBSTACLE");
	   !update_solving_position; 
	   // vybere optimalni smer do solving_dir
	   !choose_optimal_solving_dir;
	   ?solving_dir(D);
	   -solving_dir(_);
	   // jde tim smerem
	   do(D);
	   if (is(TargetDir,D)) {
	       !reset_solving_obstacle;
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

// jdu normalne za cilem po y-ove ose
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

////////////////////////////////////////////////////////////////////////////////
// MAIN - plany pro rizeni agenta (stavovy automat a obsluzne plany typu goto)
////////////////////////////////////////////////////////////////////////////////

// udela jeden krok k prvni naplanovane pozici
// pokud nejsou zadne naplanovane pozice, jde tam, kde jeste nebyl
+!goto_next_position
    <- // pokud nemas prazdny plan, tak jedem
	   if(not empty_goto_plan) {
	       //.print("NOT EMPTY GOTO PLAN");
	       // ziskani prvni pozice z planu, kam se ma jet
	       ?get_first_position(X,Y);
		   // Pokud je tam prekazka (tzn pozice byla naplanovana pred tim, nez
		   // jsem uvidel, ze tam je prekazka), tak tam nejedu a pokracuju dal.
		   if (known_obstacle(X,Y) | obstacle(X,Y)) {
		       //.print("KNOWN OBSTACLE | OBSTACLCE");
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

+!go_harvesting
    <- ?get_first_position(X,Y);
	   if (pos(X,Y)) {
	       // pokud uz je na miste, vezme surovinu
	       do(pick);
		   // TODO: kolik je surovin na jednom miste? Tady by asi melo byt, ze
		   // pokud uz tam zadna surovina nezbyla, tak by ji mel oddelat z planu,
		   // ale jinak by mel tuto pozici v planu nechat!
		   //!pop_first_position; // oddela toto misto z planu
		   // a predela rozhodne se jit do depotu
		   -state(_);
		   +state(going_to_depot)
	   }
	   else {
	       !goto(X,Y)
	   }.

+!goto_depot : depot(DepX,DepY)
    <- if (pos(DepX,DepY)) {
	       // pokud uz je v depotu, polozi tady surovinu a jde sbirat dal
		   do(drop)
	   }
	   else {
	       !goto(DepX,DepY)
	   }.

+!set_next_state
    <- // pokud hleda (prohledava mapu) a uz nema nic co prohledavat, jde tezit
	   if (all_visited & empty_goto_plan) {
	       //.print("***********************************");
	       //.print("****** TED JDU TEZIT");
		   //.print("***********************************");
           // kdyz uz vsechno navstivil a nema nic v planu, jde sbirat suroviny
		   -state(_);
		   +state(harvesting);
		   // Informing friend agents that I see the whole board.
		   ?get_middle_name(MiddleName);
		   .send(MiddleName, tell, searchingFinished);
		   ?get_slow_name(SlowName);
		   .send(SlowName,tell,searchingFinished);
		   // This will nnot be used, middle agent sents me where I should go.
		   //!plan_harvesting
	   }
	   // pokud jde do deptotu se surovinou
	   else { if (state(going_to_depot)) {
	       // pokud je uz v depotu a odevzdal surovinu, jde dal sbirat
	       ?pos(X,Y);
		   if (depot(X,Y)) {
		       -state(_);
			   +state(harvesting);
			   // pokud uz nema zadnou tezbu v planu, tak ji naplanuje
			   if (empty_goto_plan) {
			       !plan_harvesting
			   }
		   }
	   }
	   else {
	       -state(_);
		   +state(searching)
	   }}.

+!do_step : state(harvesting)
	<- do(skip).
	   
// dela kroky dokud v danem kole muze
+!do_step : moves_left(M) & pos(MyX,MyY) & M > 0
      <- // zaznamenam, si, kde jsem a co vidim
         !register_visited;
		 ?get_first_position(X,Y);
		 // pokud jsem u cile, smazu ho z goto planu
		 if (get_first_position(MyX,MyY)) {
		     //.print("MAZU SOLVING POSITION a SOLVING OBSTACLE");
		     !pop_first_position;
			 // pokud jsem obchazel prekazky, vymazu databazi
			 !reset_solving_obstacle;
			 .abolish(solving_position(_,_,_));
		 }
		 // nastavi se novy stav agenta
	     !set_next_state;
         // prida vsechny prekazky o kterych vi toto kolo
         !register_obstacles;
	     // pokud vyhledava suroviny
         if(state(searching)) {
             // prida vsechno zlato a drevo, o kterych vi toto kolo
             !register_gold;
             !register_wood;
             // jde na dalsi naplanovanou pozici
             !goto_next_position
         } 
		 else { if (state(harvesting)) {
		     // tezi zlato / drevo - stav, kdy jde k surovine a taky kdyz ji zveda
			 //!go_harvesting
			 do(skip);
		 }
		 else { if (state(going_to_depot)) {
			 !goto_depot
		 }
		 else {
		     // jinak nevim co mam delat.
			 do(skip)
		 }}}.

+!do_step.

+not_wood(X,Y)
	<- -known_wood(X,Y).
+not_gold(X,Y)
	<- -known_gold(X,Y).
	
// v prvnim kroku se nageneruji nenavstivene pozice
+step(0) <- !generate_unvisited; !do_step; !do_step; !do_step.
+step(X) <- !do_step; !do_step; !do_step.
