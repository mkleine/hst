-----------------------------------------------------------------------
  Copyright © 2008 Douglas Creager

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later
    version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free
    Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
    MA 02111-1307 USA
------------------------------------------------------------------------

> module HST.CSPM.Patterns
>     (
>      valueMatches
>     )
>     where

> import Data.List (unfoldr)
> import Data.Maybe (catMaybes)
> import Monad (liftM)

> import qualified HST.CSPM.Sets as Sets
> import HST.CSPM.Types


Returns a list of all possible “splits” of a list.  Equivalent to

  map (\x -> splitAt x l) [0..]

but (hopefully) more efficient.

> splitsOf :: [a] -> [([a], [a])]
> splitsOf l = unfoldr splitter ([], l)
>     where
>       splitter ([], []) = Nothing
>       splitter (pre, []) = Just ((pre, []), ([], []))
>       splitter (pre, post@(p:ps)) = Just ((pre, post), (pre ++ [p], ps))


> valueMatches :: Pattern -> Value -> PatternMatch


A numeric literal pattern matches a number, but only if the value is
the same.  No bindings are created.

> valueMatches (PNLit i1) (VNumber i2)
>     | (i1 == i2) = Just []
>     | otherwise  = Nothing

A wildcard pattern matches anything.  No bindings are created.

> valueMatches PWildcard _ = Just []

An identifier pattern matches anything, and binds that value to the
identifier in question.

> valueMatches (PIdentifier id) val = Just [Binding id (EValue val)]

A tuple pattern matches a tuple value, but only if all of the
sub-patterns match all of the respective sub-values.  If the tuples
are of different lengths, the match fails.  If any of the sub-patterns
create bindings, these bindings are concatenated together to create
the tuple match's bindings.

> valueMatches (PTuple ps) (VTuple vs)
>     -- The sequence function, when applied to a list of Maybes, will
>     -- return Nothing if any element of the list is Nothing.
>     = liftM concat $ sequence zipped
>     where
>       zipped = zipper ps vs
>       -- zipper creates a list of the sub-pattern matches.  Because
>       -- of how we use sequence below, the second and third clauses
>       -- will cause the match to fail (by adding a failed match into
>       -- the list) whenever the list of sub-patterns and sub-values
>       -- aren't of the same size.
>       zipper (p:ps) (v:vs) = (valueMatches p v) : zipper ps vs
>       zipper (p:ps) []     = [Nothing]
>       zipper []     (v:vs) = [Nothing]
>       zipper []     []     = []

A sequence pattern matches a sequence value, but only if all of the
sub-patterns match all of the respective sub-values.  If the sequences
are of different lengths, the match fails.  If any of the sub-patterns
create bindings, these bindings are concatenated together to create
the sequence match's bindings.

> valueMatches (PQLit ps) (VSequence vs)
>     -- The sequence function, when applied to a list of Maybes, will
>     -- return Nothing if any element of the list is Nothing.
>     = liftM concat $ sequence zipped
>     where
>       zipped = zipper ps vs
>       -- zipper creates a list of the sub-pattern matches.  Because
>       -- of how we use sequence below, the second and third clauses
>       -- will cause the match to fail (by adding a failed match into
>       -- the list) whenever the list of sub-patterns and sub-values
>       -- aren't of the same size.
>       zipper (p:ps) (v:vs) = (valueMatches p v) : zipper ps vs
>       zipper (p:ps) []     = [Nothing]
>       zipper []     (v:vs) = [Nothing]
>       zipper []     []     = []

A concatenation pattern matches a sequence value if there is any one
split of the sequence where the head matches the first pattern, and
the tail matches the second.  If there's more than one possible match,
then CSPM says that the pattern must fail.  (Technically, it should
also be an *error*, but we don't do that just yet.)

> valueMatches (PQConcat p1 p2) (VSequence vs)
>     -- catMaybes throws out all of the failed matches.  If there is
>     -- exactly one successful match left, that's our overall match.
>     = case catMaybes allMatches of
>         [match] -> Just match
>         _       -> Nothing
>     where
>       splits = splitsOf vs
>       -- matcher tries to match one split of the sequence.  We use
>       -- the same concat/sequence trick as above to merge it into a
>       -- single match iff both sub-matches succeed.
>       matcher (vs1, vs2) = liftM concat $
>                            sequence [valueMatches p1 (VSequence vs1),
>                                      valueMatches p2 (VSequence vs2)]
>       -- allMatches is a list of PatternMatch objects, one for each
>       -- possible split of the sequence.
>       allMatches = map matcher splits

An empty set pattern matches the empty set.  No bindings are created.

> valueMatches PSEmpty (VSet s)
>     | Sets.null s = Just []
>     | otherwise   = Nothing

A singleton pattern matches a set with one element, as long as the
sub-pattern matches that element.  If the sub-pattern creates a
binding, the singleton pattern creates it too.

> valueMatches (PSSingleton p) (VSet s)
>     = case l of
>         [v] -> valueMatches p v
>         _   -> Nothing
>     where
>       l = Sets.toList s

A conjunction pattern matches if both sub-patterns match the single
input value.  The conjunction creates all of the bindings that the
sub-patterns create.

> valueMatches (PConjunction p1 p2) v
>     = do
>       bs <- sequence [valueMatches p1 v, valueMatches p2 v]
>       return $ concat bs

These rules catch the cases where the value doesn't type-check against
what the pattern expects to receive.  This results in a failed match.

> valueMatches (PNLit _)       _ = Nothing
> valueMatches (PTuple _)      _ = Nothing
> valueMatches (PQLit _)       _ = Nothing
> valueMatches (PQConcat _ _)  _ = Nothing
> valueMatches PSEmpty         _ = Nothing
> valueMatches (PSSingleton _) _ = Nothing
