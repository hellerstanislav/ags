/**
 *  AGS project - environment model
 *  Based on gold-miners example
 *  @author Jan Horáček <ihoracek@fit.vutbr.cz>
 */

package mining;

import jason.environment.grid.GridWorldModel;
import jason.environment.grid.Location;
import java.util.Random;

import java.awt.Color;
import java.awt.Graphics;
import java.util.HashSet;
import java.util.Set;
import java.util.logging.Logger;

import mining.MiningPlanet.Move;

/**
  *  Model of the world
  *  @warning Singleton Class
  *  @warning Input/Output methods have to be synchronized (if it is not synchronized from Jason)
  */
public class WorldModel extends GridWorldModel
{
  public static final int   GOLD  = 16;
  public static final int   DEPOT = 32;
  public static final int   WOOD  = 64;

  private Location depot;
  private int goldsInDepotA = 0;
  private int goldsInDepotB = 0;
  private int woodsInDepotA = 0;
  private int woodsInDepotB = 0;
  private int initialNbGolds = 0;
  private int initialNbWoods = 0;
  private int simultanouslyPickedGold = 0; //if picked at same round, increase stop condition of isAllGoldsCollected
  private int simultanouslyPickedWood = 0; //if picked at same round, increase stop condition of isAllGoldsCollected
  private Set<Location> pickedGoldThisRound = new HashSet<Location>(); //if picked at same round and from the same position, all agents recieve that gold
  private Set<Location> pickedWoodThisRound = new HashSet<Location>(); //if picked at same round and from the same position, all agents recieve that gold
  
  private int aMoves = 6;
  private int bMoves = 6;
  private int nMoves = 12;
  private int[] leftMoves = new int[6];
  private int[] agCapacity = new int[6];
  private int[] carryingGold = new int[6];
  private int[] carryingWood = new int[6];

  private Logger            logger   = Logger.getLogger("jasonTeamSimLocal.mas2j." + WorldModel.class.getName());

  private String            id = "WorldModel";
  
  /**
    *  Results of actions
    *  @note ERROR could mean cheating
    */
  public enum ActionResult
  {
    OK(0), MISTAKE(1), ROUND_FINISHED(2), SIMULATION_ENDS(3), ERROR(-1);
    private int val;
    
    ActionResult(int i)
    {
      val = i;
    }
    
    boolean isNotError()
    {
      return (val>=0);
    }
  };
  
  // singleton pattern
  protected static WorldModel model = null;
  
  synchronized public static WorldModel create(int w, int h, int nbAgs)
  {
    if (model == null)
    {
      model = new WorldModel(w, h, nbAgs);
    }
    return model;
  }
  
  public static WorldModel get()
  {
    return model;
  }
  
  public static void destroy()
  {
    model = null;
  }

  private WorldModel(int w, int h, int nbAgs)
  {
    super(w, h, nbAgs);
    agCapacity[0] = 5;
    agCapacity[1] = 3;
    agCapacity[2] = 1;
    agCapacity[3] = 5;
    agCapacity[4] = 3;
    agCapacity[5] = 1;
    carryingGold[0] = 0;
    carryingGold[1] = 0;
    carryingGold[2] = 0;
    carryingGold[3] = 0;
    carryingGold[4] = 0;
    carryingGold[5] = 0;
    carryingWood[0] = 0;
    carryingWood[1] = 0;
    carryingWood[2] = 0;
    carryingWood[3] = 0;
    carryingWood[4] = 0;
    carryingWood[5] = 0;
    initMoves();
  }

  public String getId()
  {
    return id;
  }
  public void setId(String id)
  {
    this.id = id;
  }
  public String toString()
  {
    return id;
  }
  
  /**
    *  Where is depot
    */
  public Location getDepot()
  {
    return depot;
  }
  
  /**
    *  How much gold has team A
    */
  synchronized public int getGoldsInDepotA()
  {
    return goldsInDepotA;
  }
  
  /**
    *  How much gold has team B
    */
  synchronized public int getGoldsInDepotB()
  {
    return goldsInDepotB;
  }

  /**
    *  How much wood has team A
    */
  synchronized public int getWoodsInDepotA()
  {
    return woodsInDepotA;
  }

  /**
    *  How much wood has team B
    */
  synchronized public int getWoodsInDepotB()
  {
    return woodsInDepotB;
  }
  
  /**
    *  Is all gold collected?
    */
  synchronized public boolean isAllGoldsCollected()
  {
    return (goldsInDepotA + goldsInDepotB - simultanouslyPickedGold) >= initialNbGolds;
  }

  /**
    *  Is all gold collected?
    */
  synchronized public boolean isAllWoodsCollected()
  {
    return (woodsInDepotA + woodsInDepotB - simultanouslyPickedWood) >= initialNbWoods;
  }
  
  synchronized public void setInitialNbGolds(int i)
  {
    initialNbGolds = i;
  }
  
  synchronized public int getInitialNbGolds()
  {
    return initialNbGolds;
  }

  synchronized public void setInitialNbWoods(int i)
  {
    initialNbWoods = i;
  }

  synchronized public int getInitialNbWoods()
  {
    return initialNbWoods;
  }

  synchronized public int getTotalNbGolds()
  {
    return initialNbGolds + simultanouslyPickedGold;
  }

  synchronized public int getTotalNbWoods()
  {
    return initialNbWoods + simultanouslyPickedWood;
  }

  /**
    *  How much gold is carryed by an agent
    */
  synchronized public int carryingGoldGet(int ag)
  {
    return carryingGold[ag];
  }

  /**
    *  How much gold is carryed by an agent
    */
  synchronized public int carryingWoodGet(int ag)
  {
    return carryingWood[ag];
  }
  
  /**
    *  What is capacity of gold of an agent
    */
  synchronized public int agCapacityGet(int ag)
  {
    return agCapacity[ag];
  }

  /**
    *  Set depot position
    */
  private void setDepot(int x, int y)
  {
    depot = new Location(x, y);
    data[x][y] = DEPOT;
  }

  /**
    *  Set agent position
    *  @note Agents can now have the same position (problem with removing agent repaired)
    *  @note xpokor04 2010-03-11: Fixed bugs connected with the attempt to persuade gold-miners' classes to do another job :-)
    */
  @Override
  public void setAgPos(int ag, Location l)
  {
    Location oldLoc = getAgPos(ag);
    if (oldLoc != null) {
      boolean reallyDeleteAgent = true;
      for (int i = 0; i < agPos.length; i++)
      {
        if (ag != i)
        {
          Location otherLoc = getAgPos(i);
          if ((otherLoc.x == oldLoc.x) && (otherLoc.y == oldLoc.y))
          {
            reallyDeleteAgent = false;

            /* redraw original agent that stays at the place;  drawEmpty necessary to get rid of
               little rectangles belonging to throughgoing agents */
            Graphics g = view.getCanvas().getGraphics();
            view.drawEmpty(g, otherLoc.x, otherLoc.y);
            view.drawAgent(g, otherLoc.x, otherLoc.y, Color.black /*won't be used*/, i);

            break;
          }
        }
      }
      if (reallyDeleteAgent)
      {
        remove(AGENT, oldLoc.x, oldLoc.y);
      }
    }
    agPos[ag] = l;
    add(AGENT, l.x, l.y);
  }
  
  /**
    *  Is position free
    *  @note Added GOLD and DEPOT type
    */
  @Override
  public boolean isFree(int x, int y)
  {
    return inGrid(x, y) && (data[x][y] & OBSTACLE) == 0 && (data[x][y] & AGENT) == 0 && (data[x][y] & GOLD) == 0 && (data[x][y] & DEPOT) == 0;
  }

  private void initMoves()
  {
    aMoves = 6;
    bMoves = 6;
    nMoves = 12;
    leftMoves[0] = movesPerRound(0);
    leftMoves[1] = movesPerRound(1);
    leftMoves[2] = movesPerRound(2);
    leftMoves[3] = movesPerRound(3);
    leftMoves[4] = movesPerRound(4);
    leftMoves[5] = movesPerRound(5);
    pickedGoldThisRound.clear();
    pickedWoodThisRound.clear();
  }
  
  /**
    *  How many moves can agent do per round
    */
  public int movesPerRound(int agId)
  {
    switch (agId)
    {
      case 0: return 1;
      case 1: return 2;
      case 2: return 3;
      case 3: return 1;
      case 4: return 2;
      case 5: return 3;
      default: return -1;
    }
  }
  
  /**
    *  How many moves left for specified agent
    */
  synchronized public int leftMovesGet(int ag)
  {
    return leftMoves[ag];
  }

  /**
    *  Maps agent name to id
    */
  public int getAgIdBasedOnName(String agName) throws Error
  {
    if (agName.equals("aSlow")) return 0;
    else
    if (agName.equals("aMiddle")) return 1;
    else
    if (agName.equals("aFast")) return 2;
    else
    if (agName.equals("bSlow")) return 3;
    else
    if (agName.equals("bMiddle")) return 4;
    else
    if (agName.equals("bFast")) return 5;
    else
    throw new Error("Wrong agent name [" + agName + "]");
  }
  
  /**
    *  Maps agent id to name
    */
  public String getAgNameBasedOnId(int agId) throws Error
  {
    if (agId == 0) return "aSlow";
    else
    if (agId == 1) return "aMiddle";
    else
    if (agId == 2) return "aFast";
    else
    if (agId == 3) return "bSlow";
    else
    if (agId == 4) return "bMiddle";
    else
    if (agId == 5) return "bFast";
    else
    throw new Error("Wrong agent ID [" + agId + "]");
  }
  
  /**
    *  Check if agent can do this action
    *  @note Cheating prevention
    */
  private ActionResult checkActions(int agId, int moves, boolean finishedOk)
  {
    if (agId < 3)
    {       
      if (((aMoves -= moves) < 0) || (leftMoves[agId] -= moves) < 0)
      {
        logger.warning("Error " + model.getAgNameBasedOnId(agId) + " trying to run more steps than alowed!!!");
        return ActionResult.ERROR;
      }
      if (aMoves == 0)
      {
        logger.info("Team A finished round");
      }
      if ((nMoves -= moves) <= 0)
      {
        logger.info("Round finished");
        initMoves();
        return ActionResult.ROUND_FINISHED;
      }        
    }
    else
    {
      if (((bMoves -= moves) < 0) || (leftMoves[agId] -= moves) < 0)
      {
        logger.warning("Error " + model.getAgNameBasedOnId(agId) + " trying to run more steps than alowed!!!");
        return ActionResult.ERROR;
      }
      if (bMoves == 0)
      {
        logger.info("Team B finished round");
      }
      if ((nMoves -= moves) <= 0)
      {
        logger.info("Round finished");
        initMoves();
        return ActionResult.ROUND_FINISHED;
      }
    }
    
    if (finishedOk)
    {
      return ActionResult.OK;
    }
    else
    {
      return ActionResult.MISTAKE;
    }
  }
  
  /**
    *  List of agents that are near by specified agent
    */
  synchronized public Set confusedAgents(int agId)
  {
    Set result = new HashSet<Integer>();
    Location pos = getAgPos(agId);
    for (int other = 0; other<6; other++)
    {
      if (agId != other)
      {
        Location l = getAgPos(other);
        if (Math.abs(l.x - pos.x) <= 1 && Math.abs(l.y - pos.y) <= 1)
          result.add(other);
      }
    }
    return result;
  }
  
  /**
    ****************
    *  Action move *
    ****************
    */
  synchronized ActionResult move(Move dir, int ag) throws Exception
  {
    Location l = getAgPos(ag);
    switch (dir) {
    case UP:
      if (isFreeOfObstacle(l.x, l.y - 1))
      {
        setAgPos(ag, l.x, l.y - 1);
        logger.info("Agent " + getAgNameBasedOnId(ag) + " moved at position [" + getAgPos(ag) + "]");
      }
      else
      {          
        return checkActions(ag, 1, false);
      }
      break;
    case DOWN:
      if (isFreeOfObstacle(l.x, l.y + 1))
      {
        setAgPos(ag, l.x, l.y + 1);
        logger.info("Agent " + getAgNameBasedOnId(ag) + " moved at position [" + getAgPos(ag) + "]");
      }
      else
      {          
        return checkActions(ag, 1, false);
      }
      break;
    case RIGHT:
      if (isFreeOfObstacle(l.x + 1, l.y))
      {
        setAgPos(ag, l.x + 1, l.y);
        logger.info("Agent " + getAgNameBasedOnId(ag) + " moved at position [" + getAgPos(ag) + "]");
      }
      else
      {          
        return checkActions(ag, 1, false);
      }
      break;
    case LEFT:
      if (isFreeOfObstacle(l.x - 1, l.y))
      {
        setAgPos(ag, l.x - 1, l.y);
        logger.info("Agent " + getAgNameBasedOnId(ag) + " moved at position [" + getAgPos(ag) + "]");
      }
      else
      {          
        return checkActions(ag, 1, false);
      }
      break;
    }
    return checkActions(ag, 1, true);
  }
  
  /**
    ****************
    *  Action skip *
    ****************
    */
  synchronized ActionResult skip(int ag)
  {        
    logger.info("Agent " + getAgNameBasedOnId(ag) + " skipped his move");
    return checkActions(ag, 1, true);
  }

   /**
    ****************
    *  Action pick *
    ****************
    */
  synchronized ActionResult pick(int ag)
  {
      Location l = getAgPos(ag);
      if (hasObject(WorldModel.GOLD, l.x, l.y) || pickedGoldThisRound.contains(l))
      {
          if (carryingWood[ag] > 0)
          {
              logger.warning("Error " + getAgNameBasedOnId(ag) + " already has some wood!!!");
              return checkActions(ag, movesPerRound(ag), false);
          }
          return pickGold(ag);
      }
      else if ((hasObject(WorldModel.WOOD, l.x, l.y) || pickedWoodThisRound.contains(l)))
      {
          if (carryingGold[ag] > 0)
          {
              logger.warning("Error " + getAgNameBasedOnId(ag) + " already has some gold!!!");
              return checkActions(ag, movesPerRound(ag), false);
          }
          return pickWood(ag);
      }
      logger.warning("Error " + getAgNameBasedOnId(ag) + " there is nothing to pick up!!!");
      return checkActions(ag, movesPerRound(ag), false);
  }

  /**
    ********************
    *  Action pickGold *
    ********************
    */
  synchronized ActionResult pickGold(int ag)
  {
    Location l = getAgPos(ag);
    int at_same_possition = 0;
    if (ag < 3)
    {
        for (int i = 0; i < 3; i++)
        {
            Location l_ally = getAgPos(i);
            if (l.x == l_ally.x && l.y == l_ally.y)
                at_same_possition++;
            
        }
    }
    else
    {
        for (int i = 3; i < 6; i++)
        {
            Location l_ally = getAgPos(i);
            if (l.x == l_ally.x && l.y == l_ally.y)
                at_same_possition++;
            
        }
    }
    //logger.info("Agents at same possition: " + at_same_possition);
    if (at_same_possition >= 2)
    {
        if (carryingGold[ag] < agCapacity[ag])
        {
          if (hasObject(WorldModel.GOLD, l.x, l.y))
          {
            remove(WorldModel.GOLD, l.x, l.y);
            pickedGoldThisRound.add(l);
            carryingGold[ag] = carryingGold[ag] + 1;
            logger.info("Agent " + getAgNameBasedOnId(ag) + " picked a gold");
            return checkActions(ag, movesPerRound(ag), true);
          }
          else if (pickedGoldThisRound.contains(l))
          {
            carryingGold[ag] = carryingGold[ag] + 1;
            simultanouslyPickedGold++;
            logger.info("Agent " + getAgNameBasedOnId(ag) + " picked a gold");
            return checkActions(ag, movesPerRound(ag), true);
          }
          else
          {
            logger.warning("Agent " + getAgNameBasedOnId(ag) + " is trying to pick gold, but there is no gold at " + l.x + "x" + l.y + "!");
          }
        }
        else
        {
          logger.warning("Agent " + getAgNameBasedOnId(ag) + " reached his capacity and cannot pick it!");
        }
        return checkActions(ag, movesPerRound(ag), false);
    }
    else
    {
      logger.warning("Agent " + getAgNameBasedOnId(ag) + " is alone at this position, cant pick it up!");
      return checkActions(ag, movesPerRound(ag), false);
    }
  }

  /**
    ********************
    *  Action pickWood *
    ********************
    */
  synchronized ActionResult pickWood(int ag)
  {
    Location l = getAgPos(ag);
    int at_same_possition = 0;
    if (ag < 3)
    {
        for (int i = 0; i < 3; i++)
        {
            Location l_ally = getAgPos(i);
            if (l.x == l_ally.x && l.y == l_ally.y)
                at_same_possition++;

        }
    }
    else
    {
        for (int i = 3; i < 6; i++)
        {
            Location l_ally = getAgPos(i);
            if (l.x == l_ally.x && l.y == l_ally.y)
                at_same_possition++;

        }
    }
    //logger.info("Agents at same possition: " + at_same_possition);
    if (at_same_possition >= 2)
    {
        if (carryingWood[ag] < agCapacity[ag])
        {
          if (hasObject(WorldModel.WOOD, l.x, l.y))
          {
            remove(WorldModel.WOOD, l.x, l.y);
            pickedWoodThisRound.add(l);
            carryingWood[ag] = carryingWood[ag] + 1;
            logger.info("Agent " + getAgNameBasedOnId(ag) + " picked a wood");
            return checkActions(ag, movesPerRound(ag), true);
          }
          else if (pickedWoodThisRound.contains(l))
          {
            carryingWood[ag] = carryingWood[ag] + 1;
            simultanouslyPickedWood++;
            logger.info("Agent " + getAgNameBasedOnId(ag) + " picked a wood");
            return checkActions(ag, movesPerRound(ag), true);
          }
          else
          {
            logger.warning("Agent " + getAgNameBasedOnId(ag) + " is trying to pick wood, but there is no wood at " + l.x + "x" + l.y + "!");
          }
        }
        else
        {
          logger.warning("Agent " + getAgNameBasedOnId(ag) + " reached his capacity and cannot pick it!");
        }
        return checkActions(ag, movesPerRound(ag), false);
    }
    else
    {
      logger.warning("Agent " + getAgNameBasedOnId(ag) + " is alone at this position, cant pick it up!");
      return checkActions(ag, movesPerRound(ag), false);
    }
  }

  /**
    ****************
    *  Action drop *
    ****************
    */
  synchronized ActionResult drop(int ag)
  {
    Location l = getAgPos(ag);
    if (l.equals(getDepot()))
    {
        if (carryingGold[ag] > 0)
        {
            if (ag < 3) {
                goldsInDepotA += carryingGold[ag];
            } else {
                goldsInDepotB += carryingGold[ag];
            }
            logger.info("Agent " + getAgNameBasedOnId(ag) + " carried " + carryingGold[ag] + " gold to depot!");
            carryingGold[ag] = 0;
        }
        else if (carryingWood[ag] > 0)
        {
            if (ag < 3) {
                woodsInDepotA += carryingWood[ag];
            } else {
                woodsInDepotB += carryingWood[ag];
            }
            logger.info("Agent " + getAgNameBasedOnId(ag) + " carried " + carryingWood[ag] + " wood to depot!");
            carryingWood[ag] = 0;
        }
        if (isAllGoldsCollected() && isAllWoodsCollected())
        {
            return ActionResult.SIMULATION_ENDS;
        }
    }
    else
    {
      logger.warning("Agent " + getAgNameBasedOnId(ag) + " trying to drop its gold outside a depot!");
    }
    return checkActions(ag, movesPerRound(ag), true);
  }

  /**
    ********************
    *  Action transfer *
    ********************
    */
  synchronized ActionResult transfer(int agTo, int agFrom, int count)
  {
      if ((carryingGold[agFrom] > 0) && (carryingWood[agTo] == 0))
      {
          return transferGold(agTo, agFrom, count);
      }
      else if ((carryingWood[agFrom] > 0) && (carryingGold[agTo] == 0))
      {
          return transferWood(agTo, agFrom, count);
      }
      else
      {
          logger.warning("Agent " + getAgNameBasedOnId(agTo) + " reached his capacity and cannot transfer it!");
          return checkActions(agTo, movesPerRound(agTo), false);
      }
  }

  /**
    ************************
    *  Action transferGold *
    ************************
    */
  synchronized ActionResult transferGold(int agTo, int agFrom, int count)
  {
    if (confusedAgents(agTo).contains(agFrom))
    {
      if (carryingGold[agTo] + count <= agCapacity[agTo])
      {
        if (((agTo < 3) && (agFrom < 3)) || ((agTo >= 3) && (agFrom >= 3)))
        {
          if (carryingGold[agFrom] - count >= 0)
          {
            carryingGold[agFrom] -= count;
            carryingGold[agTo] += count;
            logger.info("Agent " + getAgNameBasedOnId(agTo) + " transfered " + count + " gold with " + getAgNameBasedOnId(agFrom));
            return checkActions(agTo, movesPerRound(agTo), true);
          }
          else
          {
            logger.warning("Agent " + getAgNameBasedOnId(agFrom) + " doesn't have enought gold to transfer!");
          }
        }
        else
        {
          logger.warning("Agent " + getAgNameBasedOnId(agTo) + " cannot transfer gold with enemy " + getAgNameBasedOnId(agFrom));
        }
      }
      else
      {
        logger.warning("Agent " + getAgNameBasedOnId(agTo) + " reached his capacity and cannot transfer it!");
      }
    }
    else
    {
      logger.warning("Agent " + getAgNameBasedOnId(agTo) + " trying to transfer gold with " + getAgNameBasedOnId(agFrom) + ", but they are far away!");
    }
    return checkActions(agTo, movesPerRound(agTo), false);
  }

  /**
    ************************
    *  Action transferWood *
    ************************
    */
  synchronized ActionResult transferWood(int agTo, int agFrom, int count)
  {
    if (confusedAgents(agTo).contains(agFrom))
    {
      if (carryingWood[agTo] + count <= agCapacity[agTo])
      {
        if (((agTo < 3) && (agFrom < 3)) || ((agTo >= 3) && (agFrom >= 3)))
        {
          if (carryingWood[agFrom] - count >= 0)
          {
            carryingWood[agFrom] -= count;
            carryingWood[agTo] += count;
            logger.info("Agent " + getAgNameBasedOnId(agTo) + " transfered " + count + " wood with " + getAgNameBasedOnId(agFrom));
            return checkActions(agTo, movesPerRound(agTo), true);
          }
          else
          {
            logger.warning("Agent " + getAgNameBasedOnId(agFrom) + " doesn't have enought wood to transfer!");
          }
        }
        else
        {
          logger.warning("Agent " + getAgNameBasedOnId(agTo) + " cannot transfer wood with enemy " + getAgNameBasedOnId(agFrom));
        }
      }
      else
      {
        logger.warning("Agent " + getAgNameBasedOnId(agTo) + " reached his capacity and cannot transfer it!");
      }
    }
    else
    {
      logger.warning("Agent " + getAgNameBasedOnId(agTo) + " trying to transfer wood with " + getAgNameBasedOnId(agFrom) + ", but they are far away!");
    }
    return checkActions(agTo, movesPerRound(agTo), false);
  }
  
  /**
    *  World no. 1
    */
  static WorldModel world1() throws Exception
  {
    WorldModel model = WorldModel.create(35, 35, 6);
    model.setId("Scenario 1");
    model.setDepot(16, 16);
    model.setAgPos(0, 1, 0);
    model.setAgPos(1, 20, 0);
    model.setAgPos(2, 6, 26);
    model.setAgPos(3, 1, 1);
    model.setAgPos(4, 20, 1);
    model.setAgPos(5, 6, 27);
    
    Random random = new Random();
    int gold_pos = 5 + random.nextInt(5);
    int wood_pos = 5 + random.nextInt(5);
    for (int i = 0; i<gold_pos; i++)
    {
      Location l = model.getFreePos();
      if (l != null)
        model.add(WorldModel.GOLD, l.x, l.y);
    }

    for (int i = 0; i<wood_pos; i++)
    {
      Location l = model.getFreePos();
      if (l != null)
        model.add(WorldModel.WOOD, l.x, l.y);
    }

    model.setInitialNbGolds(model.countObjects(WorldModel.GOLD));
    model.setInitialNbWoods(model.countObjects(WorldModel.WOOD));
    return model;
  }

  /**
    *  World no. 2
    */
  static WorldModel world2() throws Exception
  {
    WorldModel model = WorldModel.create(35, 35, 6);
    model.setId("Scenario 2");
    model.setDepot(16, 16);
    model.setAgPos(0, 1, 0);
    model.setAgPos(1, 20, 0);
    model.setAgPos(2, 6, 26);
    model.setAgPos(3, 1, 1);
    model.setAgPos(4, 20, 1);
    model.setAgPos(5, 6, 27);

    model.add(WorldModel.OBSTACLE, 12, 3);
    model.add(WorldModel.OBSTACLE, 13, 3);
    model.add(WorldModel.OBSTACLE, 14, 3);
    model.add(WorldModel.OBSTACLE, 15, 3);
    model.add(WorldModel.OBSTACLE, 18, 3);
    model.add(WorldModel.OBSTACLE, 19, 3);
    model.add(WorldModel.OBSTACLE, 20, 3);
    model.add(WorldModel.OBSTACLE, 14, 8);
    model.add(WorldModel.OBSTACLE, 15, 8);
    model.add(WorldModel.OBSTACLE, 16, 8);
    model.add(WorldModel.OBSTACLE, 17, 8);
    model.add(WorldModel.OBSTACLE, 19, 8);
    model.add(WorldModel.OBSTACLE, 20, 8);

    model.add(WorldModel.OBSTACLE, 12, 32);
    model.add(WorldModel.OBSTACLE, 13, 32);
    model.add(WorldModel.OBSTACLE, 14, 32);
    model.add(WorldModel.OBSTACLE, 15, 32);
    model.add(WorldModel.OBSTACLE, 18, 32);
    model.add(WorldModel.OBSTACLE, 19, 32);
    model.add(WorldModel.OBSTACLE, 20, 32);
    model.add(WorldModel.OBSTACLE, 14, 28);
    model.add(WorldModel.OBSTACLE, 15, 28);
    model.add(WorldModel.OBSTACLE, 16, 28);
    model.add(WorldModel.OBSTACLE, 17, 28);
    model.add(WorldModel.OBSTACLE, 19, 28);
    model.add(WorldModel.OBSTACLE, 20, 28);

    model.add(WorldModel.OBSTACLE, 3, 12);
    model.add(WorldModel.OBSTACLE, 3, 13);
    model.add(WorldModel.OBSTACLE, 3, 14);
    model.add(WorldModel.OBSTACLE, 3, 15);
    model.add(WorldModel.OBSTACLE, 3, 18);
    model.add(WorldModel.OBSTACLE, 3, 19);
    model.add(WorldModel.OBSTACLE, 3, 20);
    model.add(WorldModel.OBSTACLE, 8, 14);
    model.add(WorldModel.OBSTACLE, 8, 15);
    model.add(WorldModel.OBSTACLE, 8, 16);
    model.add(WorldModel.OBSTACLE, 8, 17);
    model.add(WorldModel.OBSTACLE, 8, 19);
    model.add(WorldModel.OBSTACLE, 8, 20);

    model.add(WorldModel.OBSTACLE, 32, 12);
    model.add(WorldModel.OBSTACLE, 32, 13);
    model.add(WorldModel.OBSTACLE, 32, 14);
    model.add(WorldModel.OBSTACLE, 32, 15);
    model.add(WorldModel.OBSTACLE, 32, 18);
    model.add(WorldModel.OBSTACLE, 32, 19);
    model.add(WorldModel.OBSTACLE, 32, 20);
    model.add(WorldModel.OBSTACLE, 28, 14);
    model.add(WorldModel.OBSTACLE, 28, 15);
    model.add(WorldModel.OBSTACLE, 28, 16);
    model.add(WorldModel.OBSTACLE, 28, 17);
    model.add(WorldModel.OBSTACLE, 28, 19);
    model.add(WorldModel.OBSTACLE, 28, 20);

    model.add(WorldModel.OBSTACLE, 13, 13);
    model.add(WorldModel.OBSTACLE, 13, 14);

    model.add(WorldModel.OBSTACLE, 13, 16);
    model.add(WorldModel.OBSTACLE, 13, 17);

    model.add(WorldModel.OBSTACLE, 13, 19);
    model.add(WorldModel.OBSTACLE, 14, 19);

    model.add(WorldModel.OBSTACLE, 16, 19);
    model.add(WorldModel.OBSTACLE, 17, 19);

    model.add(WorldModel.OBSTACLE, 19, 19);
    model.add(WorldModel.OBSTACLE, 19, 18);

    model.add(WorldModel.OBSTACLE, 19, 16);
    model.add(WorldModel.OBSTACLE, 19, 15);

    model.add(WorldModel.OBSTACLE, 19, 13);
    model.add(WorldModel.OBSTACLE, 18, 13);

    model.add(WorldModel.OBSTACLE, 16, 13);
    model.add(WorldModel.OBSTACLE, 15, 13);

    // labirinto
    model.add(WorldModel.OBSTACLE, 2, 32);
    model.add(WorldModel.OBSTACLE, 3, 32);
    model.add(WorldModel.OBSTACLE, 4, 32);
    model.add(WorldModel.OBSTACLE, 5, 32);
    model.add(WorldModel.OBSTACLE, 6, 32);
    model.add(WorldModel.OBSTACLE, 7, 32);
    model.add(WorldModel.OBSTACLE, 8, 32);
    model.add(WorldModel.OBSTACLE, 9, 32);
    model.add(WorldModel.OBSTACLE, 10, 32);
    model.add(WorldModel.OBSTACLE, 10, 31);
    model.add(WorldModel.OBSTACLE, 10, 30);
    model.add(WorldModel.OBSTACLE, 10, 29);
    model.add(WorldModel.OBSTACLE, 10, 28);
    model.add(WorldModel.OBSTACLE, 10, 27);
    model.add(WorldModel.OBSTACLE, 10, 26);
    model.add(WorldModel.OBSTACLE, 10, 25);
    model.add(WorldModel.OBSTACLE, 10, 24);
    model.add(WorldModel.OBSTACLE, 10, 23);
    model.add(WorldModel.OBSTACLE, 2, 23);
    model.add(WorldModel.OBSTACLE, 3, 23);
    model.add(WorldModel.OBSTACLE, 4, 23);
    model.add(WorldModel.OBSTACLE, 5, 23);
    model.add(WorldModel.OBSTACLE, 6, 23);
    model.add(WorldModel.OBSTACLE, 7, 23);
    model.add(WorldModel.OBSTACLE, 8, 23);
    model.add(WorldModel.OBSTACLE, 9, 23);
    model.add(WorldModel.OBSTACLE, 2, 29);
    model.add(WorldModel.OBSTACLE, 2, 28);
    model.add(WorldModel.OBSTACLE, 2, 27);
    model.add(WorldModel.OBSTACLE, 2, 26);
    model.add(WorldModel.OBSTACLE, 2, 25);
    model.add(WorldModel.OBSTACLE, 2, 24);
    model.add(WorldModel.OBSTACLE, 2, 23);
    model.add(WorldModel.OBSTACLE, 2, 29);
    model.add(WorldModel.OBSTACLE, 3, 29);
    model.add(WorldModel.OBSTACLE, 4, 29);
    model.add(WorldModel.OBSTACLE, 5, 29);
    model.add(WorldModel.OBSTACLE, 6, 29);
    model.add(WorldModel.OBSTACLE, 7, 29);
    model.add(WorldModel.OBSTACLE, 7, 28);
    model.add(WorldModel.OBSTACLE, 7, 27);
    model.add(WorldModel.OBSTACLE, 7, 26);
    model.add(WorldModel.OBSTACLE, 7, 25);
    model.add(WorldModel.OBSTACLE, 6, 25);
    model.add(WorldModel.OBSTACLE, 5, 25);
    model.add(WorldModel.OBSTACLE, 4, 25);
    model.add(WorldModel.OBSTACLE, 4, 26);
    model.add(WorldModel.OBSTACLE, 4, 27);

    Random random = new Random();
    int gold_pos = 5 + random.nextInt(5);
    int wood_pos = 5 + random.nextInt(5);
    for (int i = 0; i<gold_pos; i++)
    {
      Location l = model.getFreePos();
      if (l != null)
        model.add(WorldModel.GOLD, l.x, l.y);
    }

    for (int i = 0; i<wood_pos; i++)
    {
      Location l = model.getFreePos();
      if (l != null)
        model.add(WorldModel.WOOD, l.x, l.y);
    }

    model.setInitialNbGolds(model.countObjects(WorldModel.GOLD));
    model.setInitialNbWoods(model.countObjects(WorldModel.WOOD));
    return model;
  }

  /**
    *  World no. 3
    */
  static WorldModel world3() throws Exception
  {
    WorldModel model = WorldModel.create(40, 40, 6);
    model.setId("Scenario 3");
    model.setDepot(16, 16);
    model.setAgPos(0, 1, 0);
    model.setAgPos(1, 20, 0);
    model.setAgPos(2, 6, 26);
    model.setAgPos(3, 1, 1);
    model.setAgPos(4, 20, 1);
    model.setAgPos(5, 6, 27);

    for (int i = 0; i<50; i++)
    {
      Location l = model.getFreePos();
      if (l != null)
        model.add(WorldModel.OBSTACLE, l.x, l.y);
    }

    Random random = new Random();
    int gold_pos = 5 + random.nextInt(5);
    int wood_pos = 5 + random.nextInt(5);
    for (int i = 0; i<gold_pos; i++)
    {
      Location l = model.getFreePos();
      if (l != null)
        model.add(WorldModel.GOLD, l.x, l.y);
    }

    for (int i = 0; i<wood_pos; i++)
    {
      Location l = model.getFreePos();
      if (l != null)
        model.add(WorldModel.WOOD, l.x, l.y);
    }

    model.setInitialNbGolds(model.countObjects(WorldModel.GOLD));
    model.setInitialNbWoods(model.countObjects(WorldModel.WOOD));
    return model;
  }
}
