module Estuary.Languages.TiempoEspacio.Observar (observar) where

import Data.List

import Text.ParserCombinators.Parsec
import qualified Text.Parsec.Prim (many)
import Text.Parsec.Language (haskellDef)
import qualified Text.ParserCombinators.Parsec.Token as P
import Sound.Tidal.Context (Pattern,ControlPattern)
import qualified Sound.Tidal.Context as Tidal
import Control.Monad (forever)

parseBP' :: (Tidal.Enumerable a, Tidal.Parseable a) => String -> Tidal.Pattern a
parseBP' = (either (const Tidal.silence)  id). Tidal.parseBP

observar :: String -> Either ParseError Tidal.ControlPattern
observar s = parse observarParser "observar" s

observarParser :: Parser Tidal.ControlPattern
observarParser = whiteSpace >> choice [
  eof >> return Tidal.silence,
  do
    expr <- nuevaOracion observarPattern
    eof
    return $ Tidal.stack expr
  ]

--Esta función divide oraciones
nuevaOracion s = sepBy s (symbol ".")

observarPattern :: Parser Tidal.ControlPattern
observarPattern = oracion

oracion :: Parser Tidal.ControlPattern
oracion = do
  nu <- option id numbers
  option () miscelanea
  option () miscelanea
  p <- option id pronouns
  h <- option id haber
  e <- option id estar
  v <- option [" "] (many verbs)
  option () miscelanea
  option () miscelanea
  a <- option id adjective
  option () miscelanea
  option () miscelanea
  n <- option id nouns
  option () miscelanea
  option () miscelanea
  n' <- option id nouns
  option () miscelanea
  option () miscelanea
  n'' <- option id nouns
  option () miscelanea
  option () miscelanea
  n''' <- option id nouns
  option () miscelanea
  option () miscelanea
  n'''' <- option id nouns
  option () miscelanea
  option () miscelanea
  n''''' <- option id nouns
  option () miscelanea
  option () miscelanea
  g <- option id animales
  option () miscelanea
  return $ nu $ p $ h $ a $ e $ g $ n $ n' $ n'' $ n''' $ n'''' $ n''''' $ Tidal.s $ parseBP' $ (unwords v)

-- ////////////////

verbs = choice [expandVerbs, try verbOrVerb'']

expandVerbs = do
  v'' <- (brackets $ many verbOrVerb'')
  o' <- option "/" operator
  n' <- option 1 int
  return $ "[" ++ (unwords v'') ++ "]" ++ o' ++ (show n')

verbOrVerb'' = choice [try changingVerb, try verbOrVerb']

changingVerb = do
  v'' <- (angles $ many verbOrVerb')
  return $ "<" ++ (unwords v'') ++ ">"

verbOrVerb' = choice [try multiplyVerb, try maybeVerb, try verbOrVerb]

multiplyVerb = do
  v' <- verbOrVerb
  (symbol "*")
  n <- int
  return $ v' ++ "*" ++ (show n)

maybeVerb = do
  v <- verbOrVerb
  (symbol "?")
  return $ v ++ "?"

verbOrVerb = choice [try verbNumber, try verb]

verbNumber = do
  v <- verb
  (symbol ":")
  s <- option 0 int
  return $ v ++ ":" ++ (show s)

-- ////////////////

miscelanea :: Parser ()
miscelanea = choice [
        reserved "en" >> return (),
        reserved "sobre" >> return (),
        reserved "el" >> return (),
        reserved "El" >> return (),
        reserved "la" >> return (),
        reserved "La" >> return (),
        reserved "las" >> return (),
        reserved "Las" >> return (),
        reserved "Puerta" >> return (),
        reserved "Puertas" >> return (),
        reserved "un" >> return (),
        reserved "Un" >> return (),
        reserved "unos" >> return (),
        reserved "Perro" >> return (),
        reserved "también" >> return (),
        reserved "mi" >> return (),
        reserved "mis" >> return (),
        reserved "con" >> return (),
        reserved "a" >> return (),
        reserved "A" >> return (),
        reserved "veces" >> return (),
        reserved "No" >> return (),
        reserved "sobre" >> return (),
        reserved "ajeno" >> return (),
        reserved "ajenos" >> return ()
      ]


-- ////////////////

numbers :: Parser (Tidal.ControlPattern -> Tidal.ControlPattern)
numbers = choice [
  (reserved "uno_" <|> reserved "dos_" <|> reserved "tres_") >> return Tidal.jux <*> numbers',
  (reserved "cuatro_" <|> reserved "cinco_" <|> reserved "seis_") >> return Tidal.juxBy <*> parentsdoublePattern <*> numbers'
  ]

numbers' :: Parser (Tidal.ControlPattern -> Tidal.ControlPattern)
numbers' = return Tidal.rev

pronouns :: Parser (Tidal.ControlPattern -> Tidal.ControlPattern)
pronouns = ((reserved "Yo" <|> reserved "yo" <|> reserved "Ella" <|> reserved "ella" <|> reserved "Tu" <|> reserved "tu") >> return Tidal.striate) <*> option 0 intPattern'

haber :: Parser (Tidal.ControlPattern -> Tidal.ControlPattern)
haber = (reserved "he" <|> reserved "He" <|> reserved "ha" <|> reserved "Ha" <|> reserved "han" <|> reserved "Han") >> return Tidal.every <*> option 0 intPattern' <*> estar

estar :: Parser (Tidal.ControlPattern -> Tidal.ControlPattern)
estar = choice [
  (reserved "estar" <|> reserved "estoy" <|> reserved "está" <|> reserved "están" <|> reserved "estado") >> option (Tidal.slow 1) (double' >>= return . Tidal.slow . pure . toRational),
  (reserved "Estar" <|> reserved "Estoy" <|> reserved "Está" <|> reserved "Están" <|> reserved "Estado") >> option (Tidal.fast 1) (double' >>= return . Tidal.fast . pure . toRational)
  ]

-- ////////////////

verb :: Parser String
verb = choice [
  (reserved "olvidar" <|> reserved "olvido" <|> reserved "olvida" <|> reserved "olvidan" <|> reserved "olvidado" <|> reserved "olvidando") >> return "olvidar",
  (reserved "pensar" <|> reserved "pienso" <|> reserved "piensa" <|> reserved "piensan" <|> reserved "pensado" <|> reserved "pensando") >> return "pensar",
  (reserved "soñar" <|> reserved "sueño" <|> reserved "sueña" <|> reserved "sueñan" <|> reserved "soñado" <|> reserved "soñando") >> return "sonar",
  (reserved "recordar" <|> reserved "recuerdo" <|> reserved "recuerda" <|> reserved "recuerdan" <|> reserved "recordado" <|> reserved "recordando") >> return "recordar",
  (reserved "extrañar" <|> reserved "extraño" <|> reserved "extraña" <|> reserved "extrañan" <|> reserved "extrañado" <|> reserved "extrañando") >> return "extranar",
  (reserved "mirar" <|> reserved "miro" <|> reserved "mira" <|> reserved "miran" <|> reserved "mirado" <|> reserved "mirando") >> return "mirar",
  (reserved "caminar" <|> reserved "camino" <|> reserved "camina" <|> reserved "caminan" <|> reserved "caminado" <|> reserved "caminando") >> return "caminar",
  (reserved "reir" <|> reserved "río" <|> reserved "ríe" <|> reserved "ríen" <|> reserved "reído" <|> reserved "riendo") >> return "reir",
  (reserved "aparece" <|> reserved "aparezco" <|> reserved "aparece" <|> reserved "aparecen" <|> reserved "aparecido" <|> reserved "apareciendo") >> return "aparece",
  (reserved "volver" <|> reserved "vuelvo" <|> reserved "vuelve" <|> reserved "vuelven" <|> reserved "vuelto" <|> reserved "volviendo") >> return "volver",
  (reserved "producir" <|> reserved "produzco" <|> reserved "produce" <|> reserved "producen" <|> reserved "producido" <|> reserved "produciendo") >> return "producir",
  espacio,
  silencio
  ]

espacio :: Parser String
espacio = (reserved "no" <|> reserved "si" <|> reserved "que" <|> reserved "sin" <|> reserved "y" <|> reserved "ni")  >> return "~"

silencio :: Parser String
silencio = reserved "silencio" >> return "~"

-- ////////////////

adjective' :: Parser Tidal.ControlPattern
adjective' = ((reserved "blanco" <|> reserved "blancos" <|> reserved "blanca" <|> reserved "blancas" <|> reserved "opaco" <|> reserved "opacos" <|> reserved "opaca" <|> reserved "opacas" <|> reserved "gris" <|> reserved "grises" <|> reserved "brillante" <|> reserved "brillantes") >> return Tidal.n) <*> option (Tidal.irand 0) (int' >>= return . Tidal.irand . pure)

adjective :: Parser (Tidal.ControlPattern -> Tidal.ControlPattern)
adjective = do
  x <- adjective'
  return (Tidal.# x)

-- ////////////////

noun :: Parser Tidal.ControlPattern
noun = choice [
  (reserved "recuerdos" >> return Tidal.up) <*> option 0 parentsdoublePattern,
  ((reserved "sueño" <|> reserved "sueños") >> return Tidal.gain) <*> option 1 parentsdoublePattern,
  ((reserved "flor" <|> reserved "flores") >> return Tidal.pan) <*> option 0.5 parentsdoublePattern,
  ((reserved "luz" <|> reserved "luces") >> return Tidal.delay) <*> option 0 parentsdoublePattern,
  ((reserved "rayo" <|> reserved "rayos") >> return Tidal.delayfeedback) <*> option 0 parentsdoublePattern,
  ((reserved "brillo" <|> reserved "brillos") >> return Tidal.delaytime) <*> option 0 parentsdoublePattern,
  ((reserved "tiempo" <|> reserved "tiempos") >> return Tidal.speed) <*> option 0 parentsdoublePattern,
  (reserved "cacahuates" >> return Tidal.shape) <*> option 0 parentsdoublePattern,
  ((reserved "ventana" <|> reserved "ventanas") >> return Tidal.begin) <*> option 0.0 parentsdoublePattern,
  ((reserved "pasillo" <|> reserved "pasillos") >> return Tidal.end) <*> option 1.0 parentsdoublePattern,
  ((reserved "puerta" <|> reserved "puertas") >> return Tidal.room) <*> option 0 parentsdoublePattern,
  ((reserved "cuarto" <|> reserved "cuartos") >> return Tidal.size) <*> option 0 parentsdoublePattern
  ]

nouns :: Parser (Tidal.ControlPattern -> Tidal.ControlPattern)
nouns = do
  x <- noun
  return (Tidal.# x)

animal :: Parser Tidal.ControlPattern
animal = choice [
  reserved "gato" >> return (Tidal.vowel (parseBP' "a")),
  reserved "gatos" >> return (Tidal.vowel (parseBP' "e")),
  reserved "felino" >> return (Tidal.vowel (parseBP' "i")),
  reserved "felinos" >> return (Tidal.vowel (parseBP' "o")),
  reserved "perro" >> return (Tidal.vowel (parseBP' "u"))
  ]

animales :: Parser (Tidal.ControlPattern -> Tidal.ControlPattern)
animales = do
  x <- animal
  return (Tidal.# x)

-- ////////////////

fakeAdjective :: Parser (Pattern Double)
fakeAdjective = (reserved "negro" <|> reserved "negros" <|> reserved "negra" <|> reserved "negras" <|> reserved "obscuro" <|> reserved "obscuros" <|> reserved "obscura" <|> reserved "obscuras") >> option (Tidal.irand 0) (intOrNegativeInt >>= return . Tidal.irand . pure)


-- ////////////////
-- Right not you can only do ([]) or (<>), not a pattern of ([][]) or (<><>)
parentsdoublePattern = choice [
   try (parens $ stringNegativeDoublePattern''),
   try (parens $ stringPattern)
   ]

stringNegativeDoublePattern'' = choice [
   try patternWithBrackets,
   try patternWithAngles
   ]

patternWithBrackets = do
  (symbol "[")
  p <-  (many muchosdoubles)
  (symbol "]")
  o <- option "/" operator
  n <- option 1 int
  return $ parseBP' $ "[" ++ (unwords p) ++ "]" ++ o ++ (show n)

-- muchosPatternWithAngles = do
--   p <- (many patternWithAngles)
--   return $ show p

patternWithAngles = do
  (symbol "<")
  p <-  (many muchosdoubles)
  (symbol ">")
  return $ parseBP' $ "<" ++ (unwords p) ++ ">"

muchosdoubles = do
  d <- double
  return $ show d

stringPattern = do
  p <-  (many muchosdoubles)
  return $ parseBP' $ (unwords p)

double' = do
  a <- parens $ float
  return a

double :: Parser Double
double = choice [
  try $ parens double,
  symbol "-" >> double >>= return . (* (-1)),
  try float,
  try $ fromIntegral <$> integer
  ]

-- /////

operators :: Parser String
operators = choice [
         reserved "+" >> return "+",
         reserved "-" >> return "-",
         reserved "*" >> return "*",
         reserved "/" >> return "/"
         ]

-- /////

intPattern' = do
  a <- parens $ intPattern
  return a

intPattern :: Parser (Pattern Int)
intPattern = do
  p <- (many muchosint)
  return $ parseBP' $ (unwords p)

muchosint = do
  d <- int
  return $ show d

intOrNegativeInt = choice [ try negativeInt', try int']

int' = do
  a <- parens $ int
  return a

negativeInt' = parens $ negativeInt

negativeInt = do
  a <- symbol "-"
  b <- int
  return $ (-1) * b

int :: Parser Int
int = fromIntegral <$> integer


--Funciones de la librería TokenParser

tokenParser :: P.TokenParser a
tokenParser = P.makeTokenParser $ haskellDef {
  P.reservedNames = []
  }

identifier = P.identifier tokenParser
reserved = P.reserved tokenParser
operator = P.operator tokenParser
reservedOp = P.reservedOp tokenParser
charLiteral = P.charLiteral tokenParser
stringLiteral = P.stringLiteral tokenParser
natural = P.natural tokenParser
integer = P.integer tokenParser
float = P.float tokenParser
naturalOrFloat = P.naturalOrFloat tokenParser
decimal = P.decimal tokenParser
hexadecimal = P.hexadecimal tokenParser
octal = P.octal tokenParser
symbol = P.symbol tokenParser
lexeme = P.lexeme tokenParser
whiteSpace = P.whiteSpace tokenParser
parens = P.parens tokenParser
braces = P.braces tokenParser
angles = P.angles tokenParser
brackets = P.brackets tokenParser
semi = P.semi tokenParser
comma = P.comma tokenParser
colon = P.colon tokenParser
dot = P.dot tokenParser
semiSep = P.semiSep tokenParser
semiSep1 = P.semiSep1 tokenParser
commaSep = P.commaSep tokenParser
commaSep1 = P.commaSep1 tokenParser
