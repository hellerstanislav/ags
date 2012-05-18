/* File: teamGSlow.asl
 * Authors: Daniela Duricekova, xduric00@stud.fit.vutbr.cz
 *			Stanislav Heller, xhelle03@stud.fit.vutbr.cz
 *			Andrej Trnkoci, xtrnko00@stud.fit.vutbr.cz
 * Description: This file implements behaviour of the slow agent. In the 
 *				first phase, when the fast agent is searching the board, the
 *				middle agent computes the distances to the positions with the gold/
 *				wood and sends the position with the minimal distance to the gold/
 *				wood (minimal for the slow and the middle agent) to the slow agent. 
 * 				Then they are going to this position, pick gold/wood and remove it 
 *				from their databases (the middle agent takes care of it). If the 
 *				next picking up will be not possible, the slow agent is going to 
 *				the depot. Next picking up is not possible, if they are full. 
 *				Otherwise, they are going to the next gold/wood. So,the slow agent 
 *				is used as a carrier or as a cloner. In the second phase, when
 *				the fast agent is not searching the board, the middle agent 
 * 				calculates the distances to the to the positions with the gold/wood
 *				(minimal for the fast and the middle agent if the slow agent is 
 *				going to depot or minimal for all agents) and sends the position
 *				with the minimal distance to the agents (to the fast agent or to
 *				both agent if the slow agent is not going to the depot).
 */

// The status of the slow agent:
// goto_depot: the slow agent is going to the depot
// goto_mine: the slow agent is mining
state(goto_mine).
 
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
solving_dir_score(right,1000).
solving_dir_score(up,Score) :- pos(X,Y) & possible(up) & solving_pos_score(X,Y-1,Score).
solving_dir_score(up,1000).
solving_dir_score(left,Score) :- pos(X,Y) & possible(left) & solving_pos_score(X-1,Y,Score).
solving_dir_score(left, 1000).
solving_dir_score(down,Score) :- pos(X,Y) & possible(down) & solving_pos_score(X,Y+1,Score).
solving_dir_score(down,1000).

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

// Goto plan. The middle and the slow agents wait for gold or wood to be added
// to their databases.
goto_plan([[]]).

// It checks if goto plan is empty.
empty_goto_plan :- goto_plan([]).

// It checks if the list is empty.
empty_list([]).

// It gets the (X, Y) coordinations from the head of the goto plan.
get_first_position(X,Y) :- goto_plan([H|T]) & first(H, X) & second(H, Y).

// It removes the first element from the goto plan list.
@a1[atomic] +!pop_first_position : goto_plan([H|T])
    <- -+goto_plan(T).
@a2[atomic] +!pop_first_position
	<- +goto_plan([[16,16]]).

// It adds point to the beginning of the goto plan.
@a3[atomic] +!prepend_to_goto_plan(X,Y)
    <- ?goto_plan(G);
	   if (not get_first_position(X,Y)) {
	       ?prepend([X,Y],G,GG);
	       -goto_plan(GG)
	   }.

// It checks if there is an obstacle between two points on x/y coordination.
obstacle_on_x_path(X1,X2,Y) :- known_obstacle(Xobs, Y) & between(Xobs, X1, X2).
obstacle_on_y_path(Y1,Y2,X) :-known_obstacle(X, Yobs) & between(Yobs, Y1, Y2).

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

// It helps to change direction when the agent tries to bypass the obstacle. 
@a4[atomic] +!change_complement_x_dir
    <- ?complement_x_dir(none, X);
	   ?complement_x_dir(X, CompX);
	   -complement_x_dir(none, _);
	   +complement_x_dir(none, CompX).

@a5[atomic] +!change_complement_y_dir
    <- ?complement_y_dir(none, Y);
	   ?complement_y_dir(Y, CompY);
	   -complement_y_dir(none, _);
	   +complement_y_dir(none, CompY).

// It removes the fact that the agent is bypassing an obstacle.
@a6[atomic] +!reset_solving_obstacle <- -solving_obstacle(_,_).

// It stores how many times the agent was on this cell as a result of bypassing 
// an obstacle. This is the way how the agent can avoid the cycles in the maze.
@a7[atomic] +!update_solving_position : pos(PosX, PosY) 
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
@a8[atomic] +!choose_optimal_solving_dir : solving_obstacle(TargetDir, SolvingDir)
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
@a9[atomic] +!goto(X,Y) : pos(X,Y) <- true.

// If agent bypasses an obstacle.
@a10[atomic] +!goto(X,Y) : solving_obstacle(TargetDir, SolvingDir) 
    <- !update_solving_position; 
	   !choose_optimal_solving_dir;
	   ?solving_dir(D);
	   -solving_dir(_);
	   do(D);
	   if (is(TargetDir,D)) {
	       !reset_solving_obstacle;
	   }.

// If agent is going along the x-axis to its goal.
@a11[atomic] +!goto(X,Y) : pos(MyX, MyY) & get_x_dir(MyX, X, Xdir) & not (Xdir == none)
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
@a12[atomic] +!goto(X,Y) : pos(MyX, MyY) & get_y_dir(MyY, Y, Ydir) & not (Ydir == none)
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

@a13[atomic] +!goto(_,_) : moves_left(Moves) & Moves > 0 <- do(skip).

@a14[atomic] +!goto(_,_).

// It registers visible obstacles.
@a15[atomic] +!register_obstacles
    <- .count(known_obstacle(A,B), ObsCount);
	   if (ObsCount > 25) {
	       .abolish(known_obstacle(_,_));
	   }
	   .findall([X,Y], obstacle(X,Y), VisibleObstacles);
	   !register_obstacles_worker(VisibleObstacles).

// It registers visible obstacles.
@a16[atomic] +!register_obstacles_worker([]) <- true.
@a17[atomic] +!register_obstacles_worker([H|T])
    <- ?first(H,X); ?second(H,Y);
	   +known_obstacle(X,Y);
	   !register_obstacles_worker(T).
	   
// Agent goes to the depot.
@a18[atomic] +!goto_depot : depot(DepX, DepY) & pos(DepX, DepY)
    <- do(drop).
	
@a19[atomic] +!goto_depot : depot(DepX, DepY)
	<- !goto(DepX,DepY).
	
// Setting the next state according to the other agents' states.	   
@a20[atomic] +!set_next_state: carrying_gold(Capacity) & Capacity > 0  
	<- -+state(goto_depot).
	  
@a21[atomic] +!set_next_state: carrying_wood(Capacity) & Capacity > 0  
	<- -+state(goto_depot).
	  
@a22[atomic] +!set_next_state
	<- -+state(goto_mine).

// Inserts information about a treasure.
@a23[atomic] +!put_treasure_at(X, Y)
	<-	-+treasureAt(X, Y).
		
@a24[atomic] +!goto_mine : moves_left(Moves) & treasureAt(TreasureX, TreasureY) &
			  pos(TreasureX, TreasureY) & ally(TreasureX, TreasureY) &
			  gold(TreasureX, TreasureY) & is(Moves,1)
    <- 	do(pick);
		-treasureAt(_, _).

@a25[atomic] +!goto_mine : moves_left(Moves) & treasureAt(TreasureX, TreasureY) &
			  pos(TreasureX, TreasureY) & ally(TreasureX, TreasureY) &
			  wood(TreasureX, TreasureY) & is(Moves,1)
    <- 	do(pick);
		-treasureAt(_, _).

@a26[atomic] +!goto_mine : moves_left(Moves) & treasureAt(TreasureX, TreasureY) &
			  not pos(TreasureX, TreasureY) & is(Moves,1)
    <-  !goto(TreasureX, TreasureY).

@a27[atomic] +!goto_mine : treasureAt(TreasureX, TreasureY) &
			  pos(TreasureX, TreasureY) & not gold(TreasureX, TreasureY)
			  & not wood(TreasureX, TreasureY)
	<-	-treasureAt(TreasureX, TreasureY);
		do(skip).	
	
@a28[atomic] +!goto_mine : moves_left(Moves) & Moves > 0
    <- 	do(skip).
		
@a29[atomic] +!goto_mine.
		 
// It performs one move for the slow agent.
@a30[atomic] +!do_step : state(goto_depot)
      <- !register_obstacles;
	  	 !goto_depot;
	  	 !set_next_state.

@a31[atomic] +!do_step : state(goto_mine) & treasureAt(_, _)
      <- !register_obstacles;
	  	 !goto_mine;
	  	 !set_next_state.
		 
@a32[atomic] +!do_step
      <- do(skip);
	  	 !set_next_state.

@a33[atomic] +!do_step : moves_left(Moves) & Moves > 0 <- do(skip).
@a34[atomic] +!do_step.

// Agent performs one step.
+step(X) <- !do_step.
