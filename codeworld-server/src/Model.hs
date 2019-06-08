{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC
    -fno-warn-unused-imports
#-}

{-
  Copyright 2019 The CodeWorld Authors. All rights reserved.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-}
module Model where

import Control.Applicative
import Control.Monad
import Data.Aeson
import Data.Text (Text)
import System.FilePath (FilePath)
import Data.ByteString (ByteString)

data Project = Project
    { projectName :: Text
    , projectSource :: Text
    , projectHistory :: Value
    , projectOrder :: Int
    }

instance FromJSON Project where
    parseJSON (Object v) =
        Project <$> v .: "name" <*> v .: "order" <*> v .: "source" <*> v .: "history"
    parseJSON _ = mzero

instance ToJSON Project where
    toJSON p =
        object
            [ "name" .= projectName p
            , "source" .= projectSource p
            , "history" .= projectHistory p
            , "order" .= projectOrder p
            ]

data DirectoryMeta = DirectoryMeta
    { dirMetaName :: Text
    , dirMetaOrder :: Int
    } deriving (Show)

instance FromJSON DirectoryMeta where
    parseJSON (Object v) =
        DirectoryMeta <$> v .: "name" <*> v .: "order"
    parseJSON _ = mzero

instance ToJSON DirectoryMeta where
    toJSON p =
        object
            [ "name" .= dirMetaName p
            , "order" .= dirMetaOrder p
            ]

data Directory = Directory
    { files :: [Text]
    , dirs :: [Text]
    } deriving (Show)

instance ToJSON Directory where
    toJSON dir = object ["files" .= files dir, "dirs" .= dirs dir]

data CompileResult = CompileResult
    { compileHash :: Text
    , compileDeployHash :: Text
    }

instance ToJSON CompileResult where
    toJSON cr =
        object ["hash" .= compileHash cr, "dhash" .= compileDeployHash cr]

data Gallery = Gallery { galleryItems :: [GalleryItem] }
data GalleryItem = GalleryItem
    { galleryItemName :: Text,
      galleryItemURL :: Text,
      galleryItemCode :: Maybe Text
    }

instance ToJSON Gallery where
    toJSON g = object [ "items" .= galleryItems g ]

instance ToJSON GalleryItem where
    toJSON item = case galleryItemCode item of
        Nothing -> object base
        Just code -> object (("code" .= code) : base)
      where base = [ "name" .= galleryItemName item
                   , "url" .= galleryItemURL item
                   ]

data DirTree = Dir Text Int [DirTree] | Source Text Int Text deriving (Show, Eq, Ord)

instance ToJSON DirTree where
    toJSON (Source name order src) = object [ "name" .= name
                                            , "order" .= order
                                            , "data" .= src
                                            , "type" .= ("project" :: Text)
                                            ]
    toJSON (Dir name order children) = object [ "name" .= name
                                              , "order" .= order
                                              , "children" .= map toJSON children
                                              , "type" .= ("directory" :: Text)
                                              ]
 
instance FromJSON DirTree where
    parseJSON (Object v) = do
        type_ <- v .: "type"
        case type_ :: String of
            "directory" -> Dir    <$> v .: "name" <*> v .: "order" <*> v .: "children"
            "project" ->   Source <$> v .: "name" <*> v .: "order" <*> v .: "data" 
    parseJSON _ = mzero