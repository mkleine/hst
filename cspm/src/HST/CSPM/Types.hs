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

module HST.CSPM.Types where

import Data.Map (Map)
import qualified Data.Map as Map

import HST.CSPM.Sets (Set)

-- Identifiers

newtype Identifier
    = Identifier String
    deriving (Eq, Ord)

instance Show Identifier where
    show (Identifier s) = s

    -- We don't want to show the [] brackets when showing a list of
    -- identifiers.

    showList []     = showString ""
    showList (x:xs) = shows x . showl xs
                      where
                        showl []     = id
                        showl (x:xs) = showChar ' ' . shows x . showl xs

data Binding
    = Binding Identifier Expression
    deriving (Eq, Ord)

instance Show Binding where
    show (Binding id x) = show id ++ " = " ++ show x

-- Environments

data Env
    = Env {
        table  :: Map Identifier Expression,
        parent :: Maybe Env
      }
    deriving (Eq, Ord)

-- Values

data Value
    = VBottom
    | VNumber Int
    | VSequence [Value]
    | VSet (Set Value)
    | VBoolean Bool
    | VTuple [Value]
    | VLambda Env [Identifier] Expression
    deriving (Eq, Ord)

instance Show Value where
    show (VBottom)         = "Bottom"
    show (VNumber i)       = show i
    show (VSequence s)     = "<" ++ show s ++ ">"
    show (VSet s)          = "{" ++ show s ++ "}"
    show (VBoolean b)      = show b
    show (VTuple t)        = "(" ++ show t ++ ")"
    show (VLambda e ids x) = "\\ " ++ show ids ++ ": " ++ show x

    -- We don't want to show the [] brackets when showing a list of
    -- values, since we're going to use different brackets depending
    -- on whether the list represents a sequence, set, or tuple.

    showList []     = showString ""
    showList (x:xs) = shows x . showl xs
                      where
                        showl []     = id
                        showl (x:xs) = showChar ',' . shows x . showl xs

coerceNumber :: Value -> Int
coerceNumber (VNumber i) = i

coerceSequence :: Value -> [Value]
coerceSequence (VSequence s) = s

coerceSet :: Value -> (Set Value)
coerceSet (VSet a) = a

coerceBoolean :: Value -> Bool
coerceBoolean (VBoolean b) = b

coerceTuple :: Value -> [Value]
coerceTuple (VTuple t) = t

-- Expressions

data Expression
    = EBottom

    -- Expressions which evaluate to a number
    | ENLit Int
    | ENNeg Expression
    | ENSum Expression Expression
    | ENDiff Expression Expression
    | ENProd Expression Expression
    | ENQuot Expression Expression
    | ENRem Expression Expression
    | EQLength Expression
    | ESCardinality Expression

    -- Expressions which evaluate to a sequence
    | EQLit [Expression]
    | EQClosedRange Expression Expression
    | EQOpenRange Expression
    | EQConcat Expression Expression
    | EQTail Expression
    -- TODO: sequence comprehension

    -- Expressions which evaluate to a set
    | ESLit [Expression]
    | ESClosedRange Expression Expression
    | ESOpenRange Expression
    | ESUnion Expression Expression
    | ESIntersection Expression Expression
    | ESDifference Expression Expression
    | ESDistUnion Expression
    | ESDistIntersection Expression
    | EQSet Expression
    | ESPowerset Expression
    | ESSequenceset Expression
    -- TODO: set comprehension

    -- Expressions which evaluate to a boolean
    | EBTrue
    | EBFalse
    | EBAnd Expression Expression
    | EBOr Expression Expression
    | EBNot Expression
    | EEqual Expression Expression
    | ENotEqual Expression Expression
    | ELT Expression Expression
    | EGT Expression Expression
    | ELTE Expression Expression
    | EGTE Expression Expression
    | EQEmpty Expression
    | EQIn Expression Expression
    | ESIn Expression Expression
    | ESEmpty Expression

    -- Expressions which evaluate to a tuple
    | ETLit [Expression]

    -- Expressions which evaluate to a lambda
    | ELambda [Identifier] Expression

    -- Expressions which can evaluate to anything
    | EVar Identifier
    | ELet [Binding] Expression
    | EApply Expression [Expression]
    | EQHead Expression
    | EIfThenElse Expression Expression Expression
    | EBound BoundExpression

    deriving (Eq, Ord)

instance Show Expression where
    show EBottom = "Bottom"

    show (ENLit i)         = show i
    show (ENNeg m)         = "(-" ++ show m ++ ")"
    show (ENSum m n)       = "(" ++ show m ++ " + " ++ show n ++ ")"
    show (ENDiff m n)      = "(" ++ show m ++ " - " ++ show n ++ ")"
    show (ENProd m n)      = "(" ++ show m ++ " * " ++ show n ++ ")"
    show (ENQuot m n)      = "(" ++ show m ++ " / " ++ show n ++ ")"
    show (ENRem m n)       = "(" ++ show m ++ " % " ++ show n ++ ")"
    show (EQLength s)      = "(#" ++ show s ++ ")"
    show (ESCardinality a) = "(#" ++ show a ++ ")"

    show (EQLit xs)          = "<" ++ show xs ++ ">"
    show (EQClosedRange m n) = "<" ++ show m ++ ".." ++ show n ++ ">"
    show (EQOpenRange m)     = "<" ++ show m ++ "..>"
    show (EQConcat s t)      = "concat(" ++ show s ++ ", " ++ show t ++ ")"
    show (EQTail s)          = "tail(" ++ show s ++ ")"

    show (ESLit xs)              = "{" ++ show xs ++ "}"
    show (ESClosedRange m n)     = "{" ++ show m ++ ".." ++ show n ++ "}"
    show (ESOpenRange m)         = "{" ++ show m ++ "..}"
    show (ESUnion s1 s2)         = "union(" ++ show s1 ++ ", " ++ show s2 ++ "}"
    show (ESIntersection s1 s2)  = "inter(" ++ show s1 ++ ", " ++ show s2 ++ "}"
    show (ESDifference s1 s2)    = "diff(" ++ show s1 ++ ", " ++ show s2 ++ "}"
    show (ESDistUnion s1)        = "Union(" ++ show s1 ++ ")"
    show (ESDistIntersection s1) = "Inter(" ++ show s1 ++ ")"
    show (EQSet q0)              = "set(" ++ show q0 ++ ")"
    show (ESPowerset s1)         = "Set(" ++ show s1 ++ ")"
    show (ESSequenceset s1)      = "Seq(" ++ show s1 ++ ")"

    show EBTrue            = "true"
    show EBFalse           = "false"
    show (EBAnd b1 b2)     = "(" ++ show b1 ++ " && " ++ show b2 ++ ")"
    show (EBOr b1 b2)      = "(" ++ show b1 ++ " || " ++ show b2 ++ ")"
    show (EBNot b1)        = "(!" ++ show b1 ++ ")"
    show (EEqual e1 e2)    = "(" ++ show e1 ++ " == " ++ show e2 ++ ")"
    show (ENotEqual e1 e2) = "(" ++ show e1 ++ " != " ++ show e2 ++ ")"
    show (ELT e1 e2)       = "(" ++ show e1 ++ " < " ++ show e2 ++ ")"
    show (EGT e1 e2)       = "(" ++ show e1 ++ " > " ++ show e2 ++ ")"
    show (ELTE e1 e2)      = "(" ++ show e1 ++ " <= " ++ show e2 ++ ")"
    show (EGTE e1 e2)      = "(" ++ show e1 ++ " >= " ++ show e2 ++ ")"
    show (EQEmpty q0)      = "null(" ++ show q0 ++ ")"
    show (EQIn x q0)       = "elem(" ++ show x ++ ", " ++ show q0 ++ ")"
    show (ESIn x s0)       = "member(" ++ show x ++ ", " ++ show s0 ++ ")"
    show (ESEmpty s0)      = "empty(" ++ show s0 ++ ")"

    show (ETLit xs) = "(" ++ show xs ++ ")"

    show (ELambda ids x) = "\\ " ++ show ids ++ ": " ++ show x

    show (EVar id) = show id
    show (ELet bs x) = "let " ++ show bs ++ " within " ++ show x
    show (EApply x ys) = show x ++ "(" ++ show ys ++ ")"

    show (EQHead x) = "head(" ++ show x ++ ")"
    show (EIfThenElse b x y) = "if (" ++ show b ++ ") then " ++
                               show x ++ " else " ++ show y

    show (EBound be) = show be

    -- We don't want to show the [] brackets when showing a list of
    -- expressions, since we're going to use different brackets
    -- depending on whether the list represents a sequence, set, or
    -- tuple literal.

    showList []     = showString ""
    showList (x:xs) = shows x . showl xs
                      where
                        showl []     = id
                        showl (x:xs) = showChar ',' . shows x . showl xs

-- Bound expressions

data BoundExpression
    = BBottom

    -- Expressions which evaluate to a number
    | BNLit Int
    | BNNeg BoundExpression
    | BNSum BoundExpression BoundExpression
    | BNDiff BoundExpression BoundExpression
    | BNProd BoundExpression BoundExpression
    | BNQuot BoundExpression BoundExpression
    | BNRem BoundExpression BoundExpression
    | BQLength BoundExpression
    | BSCardinality BoundExpression

    -- Expressions which evaluate to a sequence
    | BQLit [BoundExpression]
    | BQClosedRange BoundExpression BoundExpression
    | BQOpenRange BoundExpression
    | BQConcat BoundExpression BoundExpression
    | BQTail BoundExpression
    -- TODO: sequence comprehension

    -- Expressions which evaluate to a set
    | BSLit [BoundExpression]
    | BSClosedRange BoundExpression BoundExpression
    | BSOpenRange BoundExpression
    | BSUnion BoundExpression BoundExpression
    | BSIntersection BoundExpression BoundExpression
    | BSDifference BoundExpression BoundExpression
    | BSDistUnion BoundExpression
    | BSDistIntersection BoundExpression
    | BQSet BoundExpression
    | BSPowerset BoundExpression
    | BSSequenceset BoundExpression
    -- TODO: set comprehension

    -- Expressions which evaluate to a boolean
    | BBTrue
    | BBFalse
    | BBAnd BoundExpression BoundExpression
    | BBOr BoundExpression BoundExpression
    | BBNot BoundExpression
    | BEqual BoundExpression BoundExpression
    | BNotEqual BoundExpression BoundExpression
    | BLT BoundExpression BoundExpression
    | BGT BoundExpression BoundExpression
    | BLTE BoundExpression BoundExpression
    | BGTE BoundExpression BoundExpression
    | BQEmpty BoundExpression
    | BQIn BoundExpression BoundExpression
    | BSIn BoundExpression BoundExpression
    | BSEmpty BoundExpression

    -- Expressions which evaluate to a tuple
    | BTLit [BoundExpression]

    -- Expressions which evaluate to a lambda
    | BLambda Env [Identifier] Expression  -- yes, that's Expr, not BoundExpr

    -- Expressions which can evaluate to anything
    | BVar Env Identifier
    | BApply BoundExpression [BoundExpression]
    | BQHead BoundExpression
    | BIfThenElse BoundExpression BoundExpression BoundExpression

    deriving (Eq, Ord)


instance Show BoundExpression where
    show BBottom = "Bottom"

    show (BNLit i)         = show i
    show (BNNeg m)         = "(-" ++ show m ++ ")"
    show (BNSum m n)       = "(" ++ show m ++ " + " ++ show n ++ ")"
    show (BNDiff m n)      = "(" ++ show m ++ " - " ++ show n ++ ")"
    show (BNProd m n)      = "(" ++ show m ++ " * " ++ show n ++ ")"
    show (BNQuot m n)      = "(" ++ show m ++ " / " ++ show n ++ ")"
    show (BNRem m n)       = "(" ++ show m ++ " % " ++ show n ++ ")"
    show (BQLength s)      = "(#" ++ show s ++ ")"
    show (BSCardinality a) = "(#" ++ show a ++ ")"

    show (BQLit xs)          = "<" ++ show xs ++ ">"
    show (BQClosedRange m n) = "<" ++ show m ++ ".." ++ show n ++ ">"
    show (BQOpenRange m)     = "<" ++ show m ++ "..>"
    show (BQConcat s t)      = "concat(" ++ show s ++ ", " ++ show t ++ ")"
    show (BQTail s)          = "tail(" ++ show s ++ ")"

    show (BSLit xs)              = "{" ++ show xs ++ "}"
    show (BSClosedRange m n)     = "{" ++ show m ++ ".." ++ show n ++ "}"
    show (BSOpenRange m)         = "{" ++ show m ++ "..}"
    show (BSUnion s1 s2)         = "union(" ++ show s1 ++ ", " ++ show s2 ++ "}"
    show (BSIntersection s1 s2)  = "inter(" ++ show s1 ++ ", " ++ show s2 ++ "}"
    show (BSDifference s1 s2)    = "diff(" ++ show s1 ++ ", " ++ show s2 ++ "}"
    show (BSDistUnion s1)        = "Union(" ++ show s1 ++ ")"
    show (BSDistIntersection s1) = "Inter(" ++ show s1 ++ ")"
    show (BQSet q0)              = "set(" ++ show q0 ++ ")"
    show (BSPowerset s1)         = "Set(" ++ show s1 ++ ")"
    show (BSSequenceset s1)      = "Seq(" ++ show s1 ++ ")"

    show BBTrue            = "true"
    show BBFalse           = "false"
    show (BBAnd b1 b2)     = "(" ++ show b1 ++ " && " ++ show b2 ++ ")"
    show (BBOr b1 b2)      = "(" ++ show b1 ++ " || " ++ show b2 ++ ")"
    show (BBNot b1)        = "(!" ++ show b1 ++ ")"
    show (BEqual e1 e2)    = "(" ++ show e1 ++ " == " ++ show e2 ++ ")"
    show (BNotEqual e1 e2) = "(" ++ show e1 ++ " != " ++ show e2 ++ ")"
    show (BLT e1 e2)       = "(" ++ show e1 ++ " < " ++ show e2 ++ ")"
    show (BGT e1 e2)       = "(" ++ show e1 ++ " > " ++ show e2 ++ ")"
    show (BLTE e1 e2)      = "(" ++ show e1 ++ " <= " ++ show e2 ++ ")"
    show (BGTE e1 e2)      = "(" ++ show e1 ++ " >= " ++ show e2 ++ ")"
    show (BQEmpty q0)      = "null(" ++ show q0 ++ ")"
    show (BQIn x q0)       = "elem(" ++ show x ++ ", " ++ show q0 ++ ")"
    show (BSIn x s0)       = "member(" ++ show x ++ ", " ++ show s0 ++ ")"
    show (BSEmpty s0)      = "empty(" ++ show s0 ++ ")"

    show (BTLit xs) = "(" ++ show xs ++ ")"

    show (BLambda e ids x) = "\\ " ++ show ids ++ ": " ++ show x

    show (BVar e id) = show id
    show (BApply x ys) = show x ++ "(" ++ show ys ++ ")"
    show (BQHead x) = "head(" ++ show x ++ ")"
    show (BIfThenElse b x y) = "if (" ++ show b ++ ") then " ++
                               show x ++ " else " ++ show y

    -- We don't want to show the [] brackets when showing a list of
    -- expressions, since we're going to use different brackets
    -- depending on whether the list represents a sequence, set, or
    -- tuple literal.

    showList []     = showString ""
    showList (x:xs) = shows x . showl xs
                      where
                        showl []     = id
                        showl (x:xs) = showChar ',' . shows x . showl xs