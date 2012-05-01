/**
  *  AGS project - environment connection with Jason
  *  Based on gold-miners example
  *  @author Jan Horáček <ihoracek@fit.vutbr.cz>
  */

package mining;

// Environment code for project jasonTeamSimLocal.mas2j

import jason.asSyntax.Literal;
import jason.asSyntax.Structure;
import jason.asSyntax.Term;
import jason.environment.grid.Location;

import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.Set;
import java.util.Iterator;
import java.util.HashSet;
import java.lang.Math;
import mining.WorldModel.ActionResult;

public class MiningPlanet extends jason.environment.Environment
{
  private Logger logger = Logger.getLogger("jasonTeamSimLocal.mas2j." + MiningPlanet.class.getName());
  
  WorldModel  model;
  WorldView   view;
  
  int     simId    = 3; // type of environment
  int     nbWorlds = 3;
  int     step     = 0;

  int     sleep    = 0;
  boolean running  = true;
  boolean hasGUI   = true;
  
  public static final int SIM_TIME = 60;  // in seconds

  Term                    up       = Literal.parseLiteral("do(up)");
  Term                    down     = Literal.parseLiteral("do(down)");
  Term                    right    = Literal.parseLiteral("do(right)");
  Term                    left     = Literal.parseLiteral("do(left)");
  Term                    skip     = Literal.parseLiteral("do(skip)");
  Term                    pick     = Literal.parseLiteral("do(pick)");
  Term                    drop     = Literal.parseLiteral("do(drop)");

  public enum Move
  {
    UP, DOWN, RIGHT, LEFT
  };

  @Override
  public void init(String[] args)
  {
    logger.setLevel(Level.INFO);
    hasGUI = args[2].equals("yes"); 
    sleep  = Integer.parseInt(args[1]);
    initWorld(Integer.parseInt(args[0]));
  }
  
  public int getSimId() {
    return simId;
  }
  
  /**
    *  Actualize step count of agent
    */
  private void signalizeStep()
  {
    logger.info("Starting round: " + step);
    removePercept(Literal.parseLiteral("step(" + (step-1) + ")"));
    addPercept(Literal.parseLiteral("step(" + step + ")"));
    step++;
  }
  
  public void setSleep(int s)
  {
    sleep = s;
  }

  @Override
  public void stop()
  {
    running = false;
    super.stop();
  }

  /**
    *  Action called from Jason
    */
  @Override
  public boolean executeAction(String ag, Structure action)
  {
    ActionResult result = ActionResult.ERROR;
    try
    {
      if (sleep > 0)
      {
        Thread.sleep(sleep);
      }
      
      // get the agent id based on its name
      int agId = model.getAgIdBasedOnName(ag);

      Set confusedBefore = model.confusedAgents(agId);
      if (action.equals(up))
      {
        result = model.move(Move.UP, agId);
      }
      else if (action.equals(down))
      {
        result = model.move(Move.DOWN, agId);
      }
      else if (action.equals(right))
      {
        result = model.move(Move.RIGHT, agId);
      }
      else if (action.equals(left))
      {
        result = model.move(Move.LEFT, agId);
      }
      else if (action.equals(skip))
      {
        result = model.skip(agId);
      }
      else if (action.equals(pick))
      {
        result = model.pick(agId);
        view.udpateCollectedGolds();
        view.udpateCollectedWoods();
      }
      else if (action.equals(drop))
      {
        result = model.drop(agId);
        view.udpateCollectedGolds();
        view.udpateCollectedWoods();
      }
      else if (action.getFunctor().toString().equals("do") && action.getTerm(0).toString().equals("transfer"))
      {
        result = model.transfer(agId, model.getAgIdBasedOnName(action.getTerm(1).toString()), Integer.parseInt(action.getTerm(2).toString()));
      }
      else
      {
        logger.info("executing: " + action + ", but not implemented!");
      }
      if (result.isNotError()) //nepodvadel nekdo?
      {
        if (result == ActionResult.MISTAKE)
        {
          logger.warning("Action " + action + " of agent " + ag + " is not possible!!!");
        }
        updateAgPercept(ag, agId);
        /*Set confusedAgents = model.confusedAgents(agId); //agents that can be confused if not informed
        confusedAgents.addAll(confusedBefore);
        Iterator<Integer> iterator = confusedAgents.iterator();
        while(iterator.hasNext())
        {
          Integer i = iterator.next();
          updateAgPercept(model.getAgNameBasedOnId(i), i);
        }*/
        if (result == ActionResult.ROUND_FINISHED)
        {
          for (int i = 0; i < 6; i++)
          {
            removePerceptsByUnif(model.getAgNameBasedOnId(i),Literal.parseLiteral("moves_left(_)"));
            addPercept(model.getAgNameBasedOnId(i), Literal.parseLiteral("moves_left(" + model.leftMovesGet(i) + ")"));
          }
	  informAgsEnvironmentChanged();
	  Thread.sleep(2);
          signalizeStep();
        }
        else if (result == ActionResult.SIMULATION_ENDS)
        {
          logger.info("All golds colected");
          stop();
        }
        informAgsEnvironmentChanged();
        return true;
      }
    }
    catch (InterruptedException e)
    {
    }
    catch (Exception e)
    {
      logger.log(Level.SEVERE, "error executing " + action + " for " + ag, e);
    }
    return false;
  }
  
  /**
    *  Called on initialisation only
    */
  public void initWorld(int w) {
    simId = w;
    try
    {
      switch (w)
      {
        case 1: model = WorldModel.world1(); break;
        case 2: model = WorldModel.world2(); break;
        case 3: model = WorldModel.world3(); break;
        default:
          logger.info("Invalid index!");
          return;
      }
      clearPercepts();
      addPercept(Literal.parseLiteral("grid_size(" + model.getWidth() + "," + model.getHeight() + ")"));
      addPercept(Literal.parseLiteral("depot("+ model.getDepot().x + "," + model.getDepot().y + ")"));
      if (hasGUI)
      {
        view = new WorldView(model);
        view.setEnv(this);
        view.udpateCollectedGolds();
        view.udpateCollectedWoods();
      }
      updateAgsPercept();
      signalizeStep();
      informAgsEnvironmentChanged();
    }
    catch (Exception e)
    {
      logger.warning("Error creating world "+e);
    }
  }
  
  /**
    *  Called when simulation ends
    */
  public void endSimulation()
  {
    addPercept(Literal.parseLiteral("end_of_simulation(" + simId + ",0)"));
    informAgsEnvironmentChanged();
    if (view != null) view.setVisible(false);
    WorldModel.destroy();
  }

  /**
    *  Apdates percepts for all agents
    */
  private void updateAgsPercept()
  {
    for (int i = 0; i < 6; i++)
    {
      updateAgPercept(model.getAgNameBasedOnId(i), i);
    }
  }

  /**
    *  Update percepts for specified agent
    *  @note agName and agId must match!
    */
  private void updateAgPercept(String agName, int ag)
  {
    clearPercepts(agName);
    // its location
    Location l = model.getAgPos(ag);
    addPercept(agName, Literal.parseLiteral("pos(" + l.x + "," + l.y + ")"));
    
    //show some variables to agent
    addPercept(agName, Literal.parseLiteral("carrying_gold(" + model.carryingGoldGet(ag) + ")"));
    addPercept(agName, Literal.parseLiteral("carrying_wood(" + model.carryingWoodGet(ag) + ")"));
    addPercept(agName, Literal.parseLiteral("carrying_capacity(" + model.agCapacityGet(ag) + ")"));
    
    addPercept(agName, Literal.parseLiteral("moves_left(" + model.leftMovesGet(ag) + ")"));
    addPercept(agName, Literal.parseLiteral("moves_per_round(" + model.movesPerRound(ag) + ")"));
    
    //friends of agent
    int i;
    if (ag < 3)
    {
      for (i = 0; i < 3; i++)
      {
        if (i != ag)
          addPercept(agName, Literal.parseLiteral("friend(" + model.getAgNameBasedOnId(i) + ")"));
      }
    }
    else
    {
      for (i = 3; i < 6; i++)
      {
        if (i != ag)
          addPercept(agName, Literal.parseLiteral("friend(" + model.getAgNameBasedOnId(i) + ")"));
      }
    }
    
    // what's around
    for (int x = l.x - 1; x <= l.x + 1; x++)
    {
      for (int y = l.y - 1; y <= l.y + 1; y++)
      {
        updateAgPercept(agName, x, y);
      }
    }
  }
  
  /**
    *  Update agent percept (what is on position x,y)
    */
  private void updateAgPercept(String agName, int x, int y)
  {
    if (model == null || !model.inGrid(x,y)) return;
    if (model.hasObject(WorldModel.OBSTACLE, x, y))
    {
      addPercept(agName, Literal.parseLiteral("obstacle(" + x + "," + y + ")"));
    }
    else
    {
      if (model.hasObject(WorldModel.GOLD, x, y))
      {
        addPercept(agName, Literal.parseLiteral("gold(" + x + "," + y + ")"));
      }
      if (model.hasObject(WorldModel.WOOD, x, y))
      {
        addPercept(agName, Literal.parseLiteral("wood(" + x + "," + y + ")"));
      }
      if (model.hasObject(WorldModel.AGENT, x, y)) //is there an agent on that position
      {
        int agId = model.getAgIdBasedOnName(agName);
        for (int other = 0; other<6; other++)
        {
          Location l = model.getAgPos(other);
          if (!(l.x == x && l.y == y))
            continue;
          if (agId != other)
          {
            if ((agId < 3 && other < 3) || (agId >= 3 && other >= 3))
            {
              addPercept(agName, Literal.parseLiteral("ally(" + x + "," + y + ")"));
            }
            else
            {
              addPercept(agName, Literal.parseLiteral("enemy(" + x + "," + y + ")"));
            }
          }
        }
      }
    }
  }
}
