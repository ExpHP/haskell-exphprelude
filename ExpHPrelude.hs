{-# LANGUAGE NoImplicitPrelude #-}

-- | BasicPrelude mostly re-exports
-- several key libraries in their entirety.
-- The exception is Data.List,
-- where various functions are replaced
-- by similar versions that are either
-- generalized, operate on Text,
-- or are implemented strictly.
module ExpHPrelude
  ( -- * Module exports
    module CorePrelude
  , module Data.List
  , module Control.Monad
  , module Debug.Trace
  , module Data.Function
  , module Control.Arrow
  , module Control.Applicative
  , module Control.DeepSeq

    -- ** Folds and traversals
  , Foldable
    (
      foldMap
    , foldr
    , foldr'
    , foldl
    , foldl'
    , foldr1
    , foldl1
    )
    -- In base-4.8, these are instance methods.
  , elem
  , maximum
  , minimum
  , toList
  , Traversable
    (
      traverse
    , sequenceA
    , mapM
    , sequence
    )

    -- * Enhanced exports
    -- ** Simpler name for a typeclassed operation
  , map
  , (++)
  , concat
  , intercalate
    -- ** Strict implementation
  , ExpHPrelude.sum
  , ExpHPrelude.product
    -- ** Text for Read and Show operations
  , tshow
  , fromShow
  , read
  , readIO
    -- ** FilePath for file operations
  , readFile
  , writeFile
  , appendFile

    -- * Text exports
    -- ** Text operations (Pure)
  , Text.lines
  , Text.words
  , Text.unlines
  , Text.unwords
  , textToString
  , ltextToString
  , fpToText
  , fpFromText
  , fpToString
  , encodeUtf8
  , decodeUtf8
    -- ** Text operations (IO)
  , Text.getLine
  , LText.getContents
  , LText.interact

    -- * Miscellaneous prelude re-exports
    -- ** Math
  , Prelude.gcd
  , Prelude.lcm
    -- ** Show and Read
  , Prelude.Show (..)
  , Prelude.ShowS
  , Prelude.shows
  , Prelude.showChar
  , Prelude.showString
  , Prelude.showParen
  , Prelude.ReadS
  , Prelude.readsPrec
  , Prelude.readList
  , Prelude.reads
  , Prelude.readParen
  , Prelude.lex
  , readMay
    -- ** IO operations
  , Prelude.putChar
  , Prelude.getChar
  , Prelude.readLn

    -- * Extra
  , traceWith
  , (<&>)
  ) where

import CorePrelude

import Data.List hiding
  ( -- prefer monoid versions instead
    (++)
  , concat
  , intercalate
    -- prefer Text versions instead
  , lines
  , words
  , unlines
  , unwords
    -- prefer map = fmap instead
  , map
    -- prefer strict versions
  , sum
  , product
    -- prefer Foldable versions
  , elem
  , foldl
  , foldl'
  , foldl1
  , foldr
  , foldr'
  , foldr1
  , maximum
  , minimum
  )

-- Import *all of the things* from Control.Monad,
-- specifically, the list-based things that
-- CorePrelude doesn't export
import Control.Monad hiding
  ( -- Also exported by Data.Traversable.
    mapM
  , sequence
  )

-- A prelude has got to have debugging in it;
-- otherwise you end up with a redundant import
-- every time you're done using them.
import Debug.Trace (trace, traceShow, traceStack, traceIO, traceShowId)

import Control.DeepSeq(deepseq, ($!!), NFData(..), force)

import Control.Applicative (Alternative, empty)
import Control.Arrow ((>>>), (<<<))
import Data.Function ((&))
import Data.Foldable (Foldable(..), elem, maximum, minimum)
import Data.Traversable (Traversable(..))
import qualified Data.Text as Text
import qualified Data.Text.IO as Text
import qualified Data.Text.Lazy as LText
import qualified Data.Text.Lazy.IO as LText
import qualified Prelude
import Data.Text.Encoding (encodeUtf8, decodeUtf8With)
import Data.Text.Encoding.Error (lenientDecode)
import qualified Safe

-- | > map = fmap
map :: (Functor f) => (a -> b) -> f a -> f b
map = fmap

infixr 5 ++

-- | > (++) = mappend
(++) :: Monoid w => w -> w -> w
(++) = mappend

-- | > concat = mconcat
concat :: Monoid w => [w] -> w
concat = mconcat

-- | > intercalate = mconcat .: intersperse
intercalate :: Monoid w => w -> [w] -> w
intercalate xs xss = mconcat (Data.List.intersperse xs xss)


-- | Compute the sum of a finite list of numbers.
sum :: (Foldable f, Num a) => f a -> a
sum = Data.Foldable.foldl' (+) 0

-- | Compute the product of a finite list of numbers.
product :: (Foldable f, Num a) => f a -> a
product = Data.Foldable.foldl' (*) 1


-- | Convert a value to readable Text
--
-- @since 0.6.0
tshow :: Show a => a -> Text
tshow = Text.pack . Prelude.show

-- | Convert a value to readable IsString
--
-- Since 0.3.12
fromShow :: (Show a, IsString b) => a -> b
fromShow = fromString . Prelude.show

-- | Parse Text to a value
read :: Read a => Text -> a
read = Prelude.read . Text.unpack

-- | The readIO function is similar to read
-- except that it signals parse failure to the IO monad
-- instead of terminating the program.
readIO :: Read a => Text -> IO a
readIO = Prelude.readIO . Text.unpack


-- | Read a file and return the contents of the file as Text.
-- The entire file is read strictly.
readFile :: FilePath -> IO Text
readFile = Text.readFile

-- | Write Text to a file.
-- The file is truncated to zero length before writing begins.
writeFile :: FilePath -> Text -> IO ()
writeFile = Text.writeFile

-- | Write Text to the end of a file.
appendFile :: FilePath -> Text -> IO ()
appendFile = Text.appendFile

textToString :: Text -> Prelude.String
textToString = Text.unpack

ltextToString :: LText -> Prelude.String
ltextToString = LText.unpack

-- | This function assumes file paths are encoded in UTF8. If it
-- cannot decode the 'FilePath', the result is just an approximation.
--
-- Since 0.3.13
fpToText :: FilePath -> Text
fpToText = Text.pack
{-# DEPRECATED fpToText "Use Data.Text.pack" #-}

-- |
-- Since 0.3.13
fpFromText :: Text -> FilePath
fpFromText = Text.unpack
{-# DEPRECATED fpFromText "Use Data.Text.unpack" #-}

-- |
-- Since 0.3.13
fpToString :: FilePath -> Prelude.String
fpToString = id
{-# DEPRECATED fpToString "Use id" #-}

-- | Note that this is /not/ the standard @Data.Text.Encoding.decodeUtf8@. That
-- function will throw impure exceptions on any decoding errors. This function
-- instead uses @decodeLenient@.
decodeUtf8 :: ByteString -> Text
decodeUtf8 = decodeUtf8With lenientDecode

readMay :: Read a => Text -> Maybe a
readMay = Safe.readMay . Text.unpack

-- | A generalization of 'traceShowId', such that @traceShowId = traceWith id@.
traceWith :: (Show b)=> (a -> b) -> a -> a
traceWith f x = traceShow (f x) x

-- | Flipped version of '<$>'
infixl 5 <&>
(<&>) :: Functor f => f a -> (a -> b) -> f b
(<&>) = flip (<$>)

-- I'm considering this, but I'm not sure how reliable it actually is
--  for arbitrary monads.
-- -- | Force a monad's contents to be fully evaluated before
-- forceM :: (NFData a, Monad m)=> m a -> m a
-- forceM = (>>= (pure $!!))
