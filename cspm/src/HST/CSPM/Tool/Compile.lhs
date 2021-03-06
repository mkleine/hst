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

> module HST.CSPM.Tool.Compile
>     (
>      cmdCompile
>     )
>     where

> import System.Console.GetOpt

> import HST.CSP0
> import HST.CSPM
> import HST.CSPM.Tool.Command

> data Options
>     = Options {
>         optInputFile   :: Maybe String,
>         optInputText   :: Maybe String
>       }
>     deriving (Eq, Ord, Show)

> defaultOptions
>     = Options {
>         optInputFile   = Nothing,
>         optInputText   = Nothing
>       }

> options :: [OptDescr (Options -> Options)]
> options =
>     [
>      Option ['i'] ["input-file"]
>      (ReqArg (\ f opts -> opts { optInputFile = Just f })
>              "FILE")
>      "file to read CSPM script from",
>      Option ['s'] ["input-script"]
>      (ReqArg (\ f opts -> opts { optInputText = Just f })
>              "SCRIPT")
>      "provide the CSPM script on the command line"
>     ]

> noScriptError
>     = ioError $ userError $
>       "You must specify either --input-file or --input-script\n" ++
>       usage_

> bothScriptError
>     = ioError $ userError $
>       "You cannot specify both --input-file and --input-script\n" ++
>       usage_

> parseOptions :: [String] -> IO (Options, [String])
> parseOptions args
>     = case getOpt RequireOrder options args of
>         (o, n, [])   -> return (foldl (flip id) defaultOptions o, n)
>         (_, _, errs) -> ioError $ userError $
>                         concat errs ++ usage_

> getScript :: Options -> IO String
> getScript opts
>     = case (optInputFile opts, optInputText opts) of
>         (Nothing, Nothing) -> noScriptError
>         (Just _, Just _)   -> bothScriptError
>         (Just f, Nothing)  -> readFile f
>         (Nothing, Just s)  -> return s

> parseAndCompile ::
>     ScriptContext BoundExpression -> String -> ScriptTransformer ()
> parseAndCompile bcontext expr
>     = case value of
>         VProcess (ProcPair dest definer) -> definer
>         _                                -> return ()
>     where
>       value = evaluateRootExpression bcontext (parseExpr expr)

> action_ args
>     = do
>       (opts, exprs) <- parseOptions args
>       scriptText <- getScript opts
>       let script   = parseFile scriptText
>           context  = createScriptContext script
>           bcontext = bindScriptContext context
>           definers = sequence $ map (parseAndCompile bcontext) exprs
>           csp0     = createScript definers
>       putStr $ outputScript csp0
>       return ()

> header = "Usage: cspm compile [OPTIONS] PROCESSES"
> description_ = "compile CSPM processes"
> usage_ = usageInfo header options

> cmdCompile
>     = Command {
>         action      = action_,
>         description = description_,
>         usage       = usage_
>       }
