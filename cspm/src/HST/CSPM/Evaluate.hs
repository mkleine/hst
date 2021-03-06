-----------------------------------------------------------------------
--
--  Copyright © 2008 Douglas Creager
--
--    This library is free software; you can redistribute it and/or
--    modify it under the terms of the GNU Lesser General Public
--    License as published by the Free Software Foundation; either
--    version 2.1 of the License, or (at your option) any later
--    version.
--
--    This library is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU Lesser General Public License for more details.
--
--    You should have received a copy of the GNU Lesser General Public
--    License along with this library; if not, write to the Free
--    Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
--    MA 02111-1307 USA
--
------------------------------------------------------------------------

module HST.CSPM.Evaluate (
                          evaluateRootExpression, evaluateWith,
                          eval, evalAsNumber, evalAsSequence,
                          evalAsSet, evalAsBoolean, evalAsTuple,
                          processEval
                         ) where

import Control.Monad.State
import Data.Map (Map)
import qualified Data.Map as Map
import qualified Data.Set as DS

import HST.CSP0 hiding (events)
import HST.CSPM.Sets (Set)
import qualified HST.CSPM.Sets as Sets
import HST.CSPM.Types
import HST.CSPM.Environments
import HST.CSPM.Bind
import HST.CSPM.Patterns

data EvalState
    = EvalState {
        eventMap     :: Map Value Event,
        defined      :: ProcessSet,
        applications :: Int
      }

instance HasProcessSet EvalState where
    getProcessSet = defined
    putProcessSet s ps = s { defined = ps }

initialState :: (ScriptContext BoundExpression) -> EvalState
initialState sc
    = state
    where
      state = EvalState em (ProcessSet DS.empty) 0
      em = Map.fromList pairs
      pairs = map makePair (Sets.toList values)
      makePair value = (value, Event $ eventName value)
      values = evalState (evalAsSet $ events sc) state

interleaveList x y = concat $ zipWith pairToList x y
    where
      pairToList x y = [x,y]

type Eval a = State EvalState a

evaluateRootExpression ::
    (ScriptContext BoundExpression) -> Expression -> Value
evaluateRootExpression = evaluateWith eval

evaluateWith ::
    (BoundExpression -> Eval a) ->
    (ScriptContext BoundExpression) -> Expression -> a
evaluateWith f sc x = evalState (f boundExpr) (initialState sc)
    where
      boundExpr = bindRootExpression (env sc) x

evalAsNumber :: BoundExpression -> Eval Int
evalAsNumber = (liftM coerceNumber) . eval

evalAsSequence :: BoundExpression -> Eval [Value]
evalAsSequence = (liftM coerceSequence) . eval

evalAsSet :: BoundExpression -> Eval (Set Value)
evalAsSet = (liftM coerceSet) . eval

evalAsBoolean :: BoundExpression -> Eval Bool
evalAsBoolean = (liftM coerceBoolean) . eval

evalAsTuple :: BoundExpression -> Eval [Value]
evalAsTuple = (liftM coerceTuple) . eval

evalAsProcess :: BoundExpression -> Eval ProcPair
evalAsProcess = (liftM coerceProcess) . eval

getEvent :: Value -> Eval Event
getEvent v = do
  em <- liftM eventMap get
  let Just event = Map.lookup v em
  return event

evalAsEvent :: BoundExpression -> Eval Event
evalAsEvent x = do
  x' <- eval x
  getEvent x'

evalAsAlphabet x = do
  vs <- evalAsSet x
  let vs' = Sets.toList vs
  es' <- sequence $ map getEvent vs'
  return $ Alphabet $ DS.fromList es'

eval :: BoundExpression -> Eval Value

eval BBottom = return VBottom

-- Expressions that evaluate to a number

eval (BNLit i) = return $ VNumber i

eval (BNNeg m) = do
  m' <- evalAsNumber m
  return $ VNumber $ negate m'

eval (BNSum m n) = do
  m' <- evalAsNumber m
  n' <- evalAsNumber n
  return $ VNumber $ m' + n'

eval (BNDiff m n) = do
  m' <- evalAsNumber m
  n' <- evalAsNumber n
  return $ VNumber $ m' - n'

eval (BNProd m n) = do
  m' <- evalAsNumber m
  n' <- evalAsNumber n
  return $ VNumber $ m' * n'

eval (BNQuot m n) = do
  m' <- evalAsNumber m
  n' <- evalAsNumber n
  return $ VNumber $ m' `quot` n'

eval (BNRem m n) = do
  m' <- evalAsNumber m
  n' <- evalAsNumber n
  return $ VNumber $ m' `rem` n'

eval (BQLength s) = do
  s' <- evalAsSequence s
  return $ VNumber $ length s'

eval (BSCardinality a) = do
  a' <- evalAsSet a
  return $ VNumber $ Sets.size a'

-- Expressions that evaluate to a sequence

eval (BQLit xs) = do
  xs' <- sequence $ map eval xs
  return $ VSequence xs'

eval (BQClosedRange m n) = do
  m' <- evalAsNumber m
  n' <- evalAsNumber n
  return $ VSequence $ map VNumber [m'..n']

eval (BQOpenRange m) = do
  m' <- evalAsNumber m
  return $ VSequence $ map VNumber [m'..]

eval (BQConcat s t) = do
  s' <- evalAsSequence s
  t' <- evalAsSequence t
  return $ VSequence $ s' ++ t'

eval (BQTail s) = do
  s' <- evalAsSequence s
  return $ VSequence $ tail s'

-- Expressions that evaluate to a set

eval BSBool = return $ VSet $ Sets.fromList [VBoolean True, VBoolean False]

eval BSInt = return $ VSet $ Sets.fromList $ map VNumber ints
    where
      ints = 0 : interleaveList pos neg
      pos  = [1..]
      neg  = [-1,-2..]

eval (BSLit xs) = do
  xs' <- sequence $ map eval xs
  return $ VSet $ Sets.fromList xs'

eval (BSClosedRange m n) = do
  m' <- evalAsNumber m
  n' <- evalAsNumber n
  return $ VSet $ Sets.fromList $ map VNumber [m'..n']

eval (BSOpenRange m) = do
  m' <- evalAsNumber m
  return $ VSet $ Sets.fromList $ map VNumber [m'..]

eval (BSUnion a b) = do
  a' <- evalAsSet a
  b' <- evalAsSet b
  return $ VSet $ a' `Sets.union` b'

eval (BSIntersection a b) = do
  a' <- evalAsSet a
  b' <- evalAsSet b
  return $ VSet $ a' `Sets.intersect` b'

eval (BSDifference a b) = do
  a' <- evalAsSet a
  b' <- evalAsSet b
  return $ VSet $ a' `Sets.difference` b'

eval (BSDistUnion aa) = do
  aa' <- evalAsSet aa
  return $ VSet $ Sets.distUnion $ Sets.map coerceSet aa'

eval (BSDistIntersection aa) = do
  aa' <- evalAsSet aa
  return $ VSet $ Sets.distIntersect $ Sets.map coerceSet aa'

eval (BQSet s) = do
  s' <- evalAsSequence s
  return $ VSet $ Sets.fromList s'

eval (BSPowerset a) = do
  a' <- evalAsSet a
  return $ VSet $ Sets.map VSet $ Sets.powerset a'

eval (BSSequenceset a) = do
  a' <- evalAsSet a
  return $ VSet $ Sets.map VSequence $ Sets.sequenceset a'

eval (BSTupleProduct xs) = do
  xs' <- sequence $ map evalAsSet xs
  return $ VSet $ Sets.fromList $ map VTuple $ Sets.productSet xs'

eval (BSDotProduct xs ys) = do
  xs' <- evalAsSet xs
  ys' <- evalAsSet ys
  return $ VSet $ Sets.fromList [ vDot x' y' | x' <- Sets.toList xs',
                                               y' <- Sets.toList ys' ]

-- Expressions that evaluate to a boolean

eval BBTrue  = return $ VBoolean True
eval BBFalse = return $ VBoolean False

eval (BBAnd b1 b2) = do
  b1' <- evalAsBoolean b1
  b2' <- evalAsBoolean b2
  return $ VBoolean $ b1' && b2'

eval (BBOr b1 b2) = do
  b1' <- evalAsBoolean b1
  b2' <- evalAsBoolean b2
  return $ VBoolean $ b1' || b2'

eval (BBNot b) = do
  b' <- evalAsBoolean b
  return $ VBoolean $ not b'

eval (BEqual x y) = do
  x' <- eval x
  y' <- eval y
  return $ VBoolean $ x' == y'

eval (BNotEqual x y) = do
  x' <- eval x
  y' <- eval y
  return $ VBoolean $ x' /= y'

eval (BLT x y) = do
  x' <- eval x
  y' <- eval y
  return $ VBoolean $ x' < y'

eval (BGT x y) = do
  x' <- eval x
  y' <- eval y
  return $ VBoolean $ x' > y'

eval (BLTE x y) = do
  x' <- eval x
  y' <- eval y
  return $ VBoolean $ x' <= y'

eval (BGTE x y) = do
  x' <- eval x
  y' <- eval y
  return $ VBoolean $ x' >= y'

eval (BQEmpty s) = do
  s' <- evalAsSequence s
  return $ VBoolean $ null s'

eval (BQIn x s) = do
  x' <- eval x
  s' <- evalAsSequence s
  return $ VBoolean $ x' `elem` s'

eval (BSIn x a) = do
  x' <- eval x
  a' <- evalAsSet a
  return $ VBoolean $ x' `Sets.member` a'

eval (BSEmpty a) = do
  a' <- evalAsSet a
  return $ VBoolean $ Sets.null a'

-- Expressions that evaluate to a tuple

eval (BTLit xs) = do
  xs' <- sequence $ map eval xs
  return $ VTuple xs'

-- Expressions that evaluate to a dot

eval (BDot x y) = do
  x' <- eval x
  y' <- eval y
  -- use the smart constructor to flatten nested dots
  return $ vDot x' y'

-- Expressions that evaluate to a lambda

eval (BLambda pfx e cs) = return $ VLambda pfx e cs

-- Expressions that can evaluate to anything

eval (BQHead s) = do
  s' <- evalAsSequence s
  return $ head s'

eval (BIfThenElse b x y) = do
  b' <- evalAsBoolean b
  case b' of
    True  -> eval x
    False -> eval y

eval (BVar e id) = eval $ bind (name e ++ id') e $ lookupExpr e id
    where
      Identifier id' = id

eval (BApply x ys) = do
  VLambda pfx e0 clauses <- eval x
  v <- eval (BTLit ys)
  case matchClause clauses v of
    Nothing         -> return VBottom
    Just (bs, body) ->
        do
          s <- get
          let apps = applications s
              nextApp = apps + 1
              e1 = extendEnv (name e0) e0 bs
              pfx' = pfx ++ "." ++ show nextApp
          put $ s { applications = nextApp }
          eval $ bind pfx' e1 body

eval (BValue v) = return v

eval (BExtractMatch id p x) = do
  v <- eval x
  case valueMatches p v of
    Nothing -> return VBottom
    Just bs -> return boundValue
      where
        binding = head $ filter finder bs
        finder (Binding id' _) = id == id'
        Binding _ (EValue boundValue) = binding

-- Expressions that can evaluate to a constructor

eval (BConstructor id) = return $ VConstructor id

-- Expressions that can evaluate to a channel

eval (BChannel id) = return $ VChannel id

-- Expressions that can evaluate to a process

eval BStop = return $ VProcess $ ProcPair stop (return ())
eval BSkip = return $ VProcess $ ProcPair skip (return ())

eval (BPrefix dest a p) = do
  processEval dest $ do
    a' <- evalAsEvent a
    ProcPair pDest pDefine <- evalAsProcess p
    return $ defineProcess dest $ do
                            defineEvent a'
                            process dest
                            pDefine
                            prefix dest a' pDest

eval (BExtChoice dest p q) = do
  processEval dest $ do
    ProcPair pDest pDefine <- evalAsProcess p
    ProcPair qDest qDefine <- evalAsProcess q
    return $ defineProcess dest $ do
                               process dest
                               pDefine
                               qDefine
                               extchoice dest pDest qDest

eval (BIntChoice dest p q) = do
  processEval dest $ do
    ProcPair pDest pDefine <- evalAsProcess p
    ProcPair qDest qDefine <- evalAsProcess q
    return $ defineProcess dest $ do
                               process dest
                               pDefine
                               qDefine
                               intchoice dest pDest qDest

eval (BTimeout dest p q) = do
  processEval dest $ do
    ProcPair pDest pDefine <- evalAsProcess p
    ProcPair qDest qDefine <- evalAsProcess q
    return $ defineProcess dest $ do
                               process dest
                               pDefine
                               qDefine
                               timeout dest pDest qDest

eval (BSeqComp dest p q) = do
  processEval dest $ do
    ProcPair pDest pDefine <- evalAsProcess p
    ProcPair qDest qDefine <- evalAsProcess q
    return $ defineProcess dest $ do
                               process dest
                               pDefine
                               qDefine
                               seqcomp dest pDest qDest

eval (BInterleave dest p q) = do
  processEval dest $ do
    ProcPair pDest pDefine <- evalAsProcess p
    ProcPair qDest qDefine <- evalAsProcess q
    return $ defineProcess dest $ do
                               process dest
                               pDefine
                               qDefine
                               interleave dest pDest qDest

eval (BIParallel dest p alpha q) = do
  processEval dest $ do
    ProcPair pDest pDefine <- evalAsProcess p
    ProcPair qDest qDefine <- evalAsProcess q
    aAlpha <- evalAsAlphabet alpha
    return $ defineProcess dest $ do
                               process dest
                               pDefine
                               qDefine
                               iparallel dest pDest aAlpha qDest

eval (BAParallel dest p alpha beta q) = do
  processEval dest $ do
    ProcPair pDest pDefine <- evalAsProcess p
    ProcPair qDest qDefine <- evalAsProcess q
    aAlpha <- evalAsAlphabet alpha
    aBeta <- evalAsAlphabet beta
    return $ defineProcess dest $ do
                               process dest
                               pDefine
                               qDefine
                               aparallel dest pDest aAlpha aBeta qDest

eval (BHide dest p alpha) = do
  processEval dest $ do
    ProcPair pDest pDefine <- evalAsProcess p
    aAlpha <- evalAsAlphabet alpha
    return $ defineProcess dest $ do
                               process dest
                               pDefine
                               hide dest pDest aAlpha

eval (BRExtChoice dest ps) = do
  processEval dest $ do
    ps' <- evalAsSet ps
    let (pDests, pDefiners) = coerceProcessSet ps'
    return $ defineProcess dest $ do
                               process dest
                               sequence $ pDefiners
                               rextchoice dest pDests

eval (BRIntChoice dest ps) = do
  processEval dest $ do
    ps' <- evalAsSet ps
    let (pDests, pDefiners) = coerceProcessSet ps'
    return $ defineProcess dest $ do
                               process dest
                               sequence $ pDefiners
                               rintchoice dest pDests

coerceProcessSet ps =
    (ProcessSet $ Sets.toSet $ Sets.map getDest pairs,
     map getDefiner $ Sets.toList pairs)
    where
      pairs = Sets.map coerceProcess ps
      getDest (ProcPair dest _) = dest
      getDefiner (ProcPair _ definer) = definer

processEval :: Process -> Eval (ScriptTransformer ()) -> Eval Value
processEval dest definer = do
  needed <- needsDefining dest
  let ifNeeded = do
        startDefining dest
        definer' <- definer
        return $ VProcess $ ProcPair dest definer'
      ifNot =
        return $ VProcess $ ProcPair dest (return ())
  if needed then ifNeeded else ifNot
