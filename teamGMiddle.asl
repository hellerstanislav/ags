/* File: teamGMiddle.asl
 * Authors: Daniela Duricekova, xduric00@stud.fit.vutbr.cz
 *			Stanislav Heller, xhelle03@stud.fit.vutbr.cz
 *			Andrej Trnkoci, xtrnko00@stud.fit.vutbr.cz
 * Description: This file implements behaviour of the middle agent. In the 
 *				first phase, when the fast agent is searching the board, the
 *				middle agent computes the distances to the positions with the gold/
 *				wood and sends the position with the minimal distance to the gold/
 *				wood (minimal for the slow and the middle agent) to the slow agent. 
 * 				Then they are going to this position, pick gold/wood and remove it 
 *				from their databases (the middle agent takes care of it). If the 
 *				next picking up will be not possible, the slow agent is going to 
 *				the depot. Next picking up is not possible, if they are full. 
 *				Otherwise, they are going to the next gold/wood. In the second phase, 
 *				when the fast agent is not searching the board, the middle agent 
 * 				calculates the distances to the positions with the gold/wood
 *				(minimal for the fast and the middle agent if the slow agent is 
 *				going to depot or minimal for all agents) and sends the position
 *				with the minimal distance to the agents (to the fast agent or to
 *				both agents if the slow agent is not going to the depot).
 */


// Obtains absolute value of X.
abs(X, X) :- X > -1.
abs(X, AbsX) :- AbsX = -X.

// It is used to determine the borders of the board.
border(X,-1).
border(-1,Y).
border(X,Y) :- grid_size(X,_).
border(X,Y) :- grid_size(_,Y).

// It determines if it is possible to go in the selected diretion.
possible(right) :- pos(MyX, MyY) & not (obstacle(MyX+1, MyY) | border(MyX+1, MyY)).
possible(up) :- pos(MyX, MyY) & not (obstacle(MyX, MyY-1) | border(MyX, MyY-1)).
possible(left) :- pos(MyX, MyY) & not (obstacle(MyX-1, MyY) | border(MyX-1, MyY)).
possible(down) :- pos(MyX, MyY) & not (obstacle(MyX, MyY+1) | border(MyX, MyY+1)).

// It complements current direction in x/y axis to the opposite direction.
complement_x_dir(left, right).
complement_x_dir(right, left).
complement_x_dir(none, left).
complement_y_dir(up, down).
complement_y_dir(down, up).
complement_y_dir(none, down).

// It complements current direction to the opposite direction.
complement_dir(left, right).
complement_dir(right, left).
complement_dir(up, down).
complement_dir(down, up).

// It returns the score of the given position (X, Y). The score is store in the
// solving_position(X, Y, Score).
solving_pos_score(X,Y,0) :- .count(solving_position(X,Y,_),0).
solving_pos_score(X,Y,Score) :- solving_position(X,Y,Score).

// It calculates the scores of all directions.
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

// TODO
is_x_dir(left).
is_x_dir(right).
is_y_dir(up).
is_y_dir(down).

// It specifies which direction should be followed according to the current position
// and the target position in x axis.
get_x_dir(MyX, TargetX, right) :- TargetX > MyX.
get_x_dir(MyX, TargetX, left) :- TargetX < MyX.
get_x_dir(MyX, TargetX, none) :- TargetX == MyX.

// It specifies which direction should be followed according to the current position
// and the target position in y axis.
get_y_dir(MyY, TargetY, up) :- TargetY < MyY.
get_y_dir(MyY, TargetY, down) :- TargetY > MyY.
get_y_dir(MyY, TargetY, none) :- TargetY == MyY.

// It gets the first coordination, second coordination from the list of the form 
// [[X,Y],[X1, Y1], ...].
first([H|_], H).
second([H|T], HH) :- first(T, HH).

// It compares two elements.
is(X,X).

// It adds an element to the front of the list.
prepend(H,[], [H]).
prepend(H,L, [H|L]).

// It tests if X lies in the interval (From, To).
between(X, From, To) :- From < To & X > From & X < To.
between(X, From, To) :- From > To & X < From & X > To.

// It computes the Euler distance of two points in 1-D.
euler_dist(A,B,Dist) :- A > B & Dist = A - B.
euler_dist(A,B,Dist) :- A < B & Dist = B - A.
euler_dist(A,B,0) :- A=B.

// It checks if goto plan is empty.
empty_goto_plan :- goto_plan([]).

// It checks if the list is empty.
empty_list([]).

// It gets the (X, Y) coordinations from the head of the goto plan.
get_first_position(X,Y) :- goto_plan([H|T]) & first(H, X) & second(H, Y).

// It removes the first element from the goto plan list.
+!pop_first_position: goto_plan([H|T])
    <- -goto_plan(_);
	   +goto_plan(T).
+!pop_first_position: .print("empty goto plan").

// It adds point to the beginning of the goto plan.
+!prepend_to_goto_plan(X,Y)
    <- ?goto_plan(G);
	   if (not get_first_position(X,Y)) {
	       ?prepend([X,Y],G,GG);
	       -goto_plan(_);
	       +goto_plan(GG)
	   }.

// It checks if there is an obstacle between two points on x/y coordination.
obstacle_on_x_path(X1,X2,Y) :- known_obstacle(Xobs, Y) & between(Xobs, X1, X2).
obstacle_on_y_path(Y1,Y2,X) :-known_obstacle(X, Yobs) & between(Yobs, Y1, Y2).

// vypocet funkce agregovane vzdalenosti od mista, kde agent je a od depotu
aggregated_distance(PosDist, DepDist, Dist) :- DepDist > 32 & Dist = (PosDist + 1.6*DepDist).
aggregated_distance(PosDist, DepDist, Dist) :- DepDist < 33 & Dist = (PosDist + 2.1*DepDist).

// It calculates the distance between two points on the same x/y coordination.
distance_x_line(X1, X2, Y, Dist) :- obstacle_on_x_path(X1,X2,Y) & 
                                    euler_dist(X1,X2,D) & 
								    Dist = D + 3.
distance_x_line(X1, X2, Y, Dist) :- euler_dist(X1,X2,Dist).
distance_y_line(Y1, Y2, X, Dist) :- obstacle_on_y_path(Y1,Y2,X) & 
                                    euler_dist(Y1,Y2,D) & 
									Dist = D + 3.
distance_y_line(Y1, Y2, X, Dist) :- euler_dist(Y1,Y2,Dist).

// It calculates the distance between two given points.
distance(MyX,MyY,X,Y,Dist) :- distance_x_line(MyX, X, Y, Dist_Y) &
							  distance_x_line(MyX, X, MyY, Dist_MyY) &
							  distance_y_line(MyY, Y, X, Dist_X) &
							  distance_y_line(MyY, Y, MyX, Dist_MyX) &
							  A = Dist_MyX + Dist_Y &
							  B = Dist_MyY + Dist_X &
							  .min([A,B],Dist).

// Computes distance from the middle to the treasure.
compute_distance_middle(MiddleDist, Dist) :-
	Dist = math.ceil(MiddleDist / 2).
							  
// Computes distance from agents (middle and slow) to the treasure.
compute_distance_middle_slow(SlowDist, MiddleDist, Dist) :-
	Dist = SlowDist + math.ceil(MiddleDist / 2).
							
// Computes distance from agents (middle and fast) to the treasure.
compute_distance_middle_fast(MiddleDist, FastDist, Dist) :-
	Dist = math.ceil(MiddleDist / 2) + math.ceil(FastDist / 3).

// Computes distance from agents (middle, fast, slow) to the treasure.
compute_distance_all(SlowDist, MiddleDist, FastDist, Dist) :-
	Dist = SlowDist + math.ceil(MiddleDist / 2) + math.ceil(FastDist / 3).
	
// It helps to compute distances to the point H in different agent's state.
compute_distance(H, Dist) :-
	state(alone) &
	pos(MiddleX, MiddleY) &
	first(H, TargetX) & second(H, TargetY) &
	distance(MiddleX, MiddleY, TargetX, TargetY, MiddleDist) &
	compute_distance_middle(MiddleDist, Dist).

compute_distance(H, Dist) :-
	state(goto_mine) &
	state(X) &
	pos(MiddleX, MiddleY) &
	aSlowPos(SlowX, SlowY) &
	first(H, TargetX) & second(H, TargetY) &
    distance(SlowX, SlowY, TargetX, TargetY, SlowDist) &
	distance(MiddleX, MiddleY, TargetX, TargetY, MiddleDist) &
	compute_distance_middle_slow(SlowDist, MiddleDist, Dist).

compute_distance(H, Dist) :-
	state(middle_fast_mine) &
	pos(MiddleX, MiddleY) &
	aFastPos(FastX, FastY) &
	first(H, TargetX) & second(H, TargetY) &
    distance(FastX, FastY, TargetX, TargetY, FastDist) &
	distance(MiddleX, MiddleY, TargetX, TargetY, MiddleDist) &
	compute_distance_middle_fast(MiddleDist, FastDist, Dist).
	
compute_distance(H, Dist) :-
	state(all_mine) &
	pos(MiddleX, MiddleY) &
	aSlowPos(SlowX, SlowY) &
	aFastPos(FastX, FastY) &
	first(H, TargetX) & second(H, TargetY) &
    distance(SlowX, SlowY, TargetX, TargetY, SlowDist) &
	distance(MiddleX, MiddleY, TargetX, TargetY, MiddleDist) &
	distance(FastX, FastY, TargetX, TargetY, FastDist) &
	compute_distance_all(SlowDist, MiddleDist, FastDist, Dist).

// This solves the situatin if aSlowPos() or aFastPos() is not updated in DB.
compute_distance(_, 1000) :- true.

// It calculates the position of gold/wood to which the agents are able to come 
// in the shortest time.
min_distance(TreasureList,TreasureListMinDist) :-
    min_distance_worker(TreasureList,1000,[], TreasureListMinDist).

min_distance_worker([], _, K, K) :- true.

min_distance_worker([H|T], MinDist, Keeper, TreasureListMinDist) :-
	compute_distance(H, Dist) &
	Dist < MinDist &
	min_distance_worker(T, Dist, [H], TreasureListMinDist).

min_distance_worker([H|T], MinDist, Keeper, TreasureListMinDist) :-
	compute_distance(H, Dist) &
	is(Dist, MinDist) & .concat([H], Keeper, NewKeeper) & 
	min_distance_worker(T, Dist, NewKeeper, TreasureListMinDist).

min_distance_worker([H|T], MinDist, Keeper, TreasureListMinDist) :-
    compute_distance(H, Dist) &
	Dist > MinDist &
	min_distance_worker(T, MinDist, Keeper, TreasureListMinDist).
					  
// It calculates the position of gold/wood where both agents (slow and middle)
// are able to come in the shortest time.
+!compute_treasure_min_dist(TreasureListMinDist) <-
	.findall([X1, Y1], known_gold(X1, Y1), Gold);
	.findall([X1, Y1], known_wood(X1, Y1), Wood);
	.concat(Gold, Wood, Treasure);
	?min_distance(Treasure, TreasureListMinDist).
	
// It helps to change direction when the agent tries to bypass the obstacle. 
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

// It removes the fact that the agent is bypassing an obstacle.
+!reset_solving_obstacle <- -solving_obstacle(_,_).

// It stores how many times the agent was on this cell as a result of bypassing 
// an obstacle. This is the way how the agent can avoid the cycles in the maze.
+!update_solving_position : pos(PosX, PosY) 
    <- if(solving_position(PosX,PosY,_)) {
	       ?solving_position(PosX,PosY,C);
		   -solving_position(PosX,PosY,_);
		   +solving_position(PosX,PosY,C+1);
	   }
	   else {
	       +solving_position(PosX,PosY,1)
	   }.

// It chooses the optimal direction for bypassing an obstacle. It is based on
// the principle of the score of every cell on the board. It is used to avoid
// problems that appear as a result of cycles' existence in the maze.
+!choose_optimal_solving_dir : solving_obstacle(TargetDir, SolvingDir)
    <- ?solving_dir_score(TargetDir, TargetScore);
	   ?solving_dir_score(SolvingDir, SolvingScore);
	   ?complement_dir(TargetDir, CompTargetDir);
	   ?solving_dir_score(CompTargetDir, CompTargetScore);
	   ?complement_dir(SolvingDir, CompSolvingDir);
	   ?solving_dir_score(CompSolvingDir, CompSolvingScore);
	   // It chooses the minimal score which represents the best path.
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
	   
// If agent is at the destination position.
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

// If agent bypasses an obstacle.
+!goto(X,Y) : solving_obstacle(TargetDir, SolvingDir) 
    <- !update_solving_position; 
	   !choose_optimal_solving_dir;
	   ?solving_dir(D);
	   -solving_dir(_);
	   do(D);
	   if (is(TargetDir,D)) {
	       !reset_solving_obstacle;
	   }.

// If agent is going along the x-axis to its goal.
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

// If agent is going along the y-axis to its goal.
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

+!goto(X,Y) <- do(skip).
	   
// It registers visible obstacles.
+!register_obstacles
    <- .count(known_obstacle(A,B), ObsCount);
	   if (ObsCount > 25) {
	       .abolish(known_obstacle(_,_));
	   }
	   .findall([X,Y], obstacle(X,Y), VisibleObstacles);
	   !register_obstacles_worker(VisibleObstacles).

+!add_known_obstacle(X, Y)
	<- +known_obstacle(X,Y).
	   
// It registers visible obstacles.
+!register_obstacles_worker([]) <- true.
+!register_obstacles_worker([H|T])
    <- ?first(H,X); ?second(H,Y);
	   +known_obstacle(X,Y);
	   !register_obstacles_worker(T).

get_fast_name(aFast) :- friend(aFast).
get_fast_name(bFast) :- friend(bFast). 
get_middle_name(aMiddle) :- friend(aMiddle).
get_middle_name(bMiddle) :- friend(bMiddle).
get_slow_name(aSlow) :- friend(aSlow).
get_slow_name(bSlow) :- friend(bSlow).
	   
treasure(X, Y) :- gold(X, Y).
treasure(X, Y) :- wood(X, Y).

+!pushPlan(X, Y): plan(Plan)
	<- ?prepend([X,Y], Plan, NewPlan);
	   -+plan(NewPlan).
+!pushPlan.

+!popPlan: plan([H|T])
    <- -+plan(T).
+!popPlan.

+!planDepo: depot(X, Y)
	<- -plan(_);
		+plan([[X, Y]]).

+!treasureFound(X, Y)
	<- +knownTreasure(X, Y).

+!planTreasure: knownTreasure(X, Y) & get_slow_name(SlowName)
	<-  .send(SlowName, untell, treasurePos(_, _));
		.send(SlowName, tell, treasurePos(X, Y));
		!pushPlan(X, Y).
+!planTreasure.

+!doStep: plan([])
	<- !planTreasure; do(skip); do(skip).
+!doStep: pos(X, Y) & plan([[X, Y]|_]) & depot(X, Y)
	<- do(drop); !popPlan.
+!doStep: pos(X, Y) & knownTreasure(X, Y) & plan([[X, Y]|_]) & ally(X, Y) & treasure(X, Y)
	<- do(pick); -knownTreasure(X, Y); !popPlan; !planDepo.
+!doStep: pos(X, Y) & knownTreasure(X, Y) & plan([[X, Y]|_]) & ally(X, Y) & not treasure(X, Y)
	<- do(skip); do(skip); -knownTreasure(X, Y); !popPlan; !planTreasure.
+!doStep: plan([[X, Y]|_]) & not pos(X, Y)
	<- !goto(X, Y); do(skip).
+!doStep <- do(skip); do(skip).

+step(0) <- +plan([]); !register_obstacles; !doStep.
+step(_) <- !register_obstacles; !doStep.
