import Color exposing (..)
import Graphics.Collage exposing (..)
import Graphics.Element exposing (..)
import String
import Text

import TreeLayout exposing (draw, Tree(..), TreeLayout)


{-| Represent edges as straight lines
-}
drawLine : (Float, Float) -> (Float, Float) -> Form
drawLine from to = segment from to |> traced (solid black)


{-| Represent nodes as circles with the node value inside
-}
drawPoint : Int -> Form
drawPoint n = let
    bubble = circle 16
  in
    group [
      bubble |> filled white,
      bubble |> outlined defaultLine,
      toString n |> Text.fromString |> Text.color black |> text
    ]


-- Tree to draw
coolTree =
  Tree 61 [
    Tree 84 [
      Tree 22 [],
      Tree 38 []
    ],
    Tree 72 [
      Tree 3 [
        Tree 59 [],
        Tree 29 [],
        Tree 54 []
      ],
      Tree 25 [],
      Tree 49 []
    ],
    Tree 24 [
      Tree 2 []
    ],
    Tree 17 [
      Tree 26 [],
      Tree 68 [
        Tree 13 [],
        Tree 36 []
      ],
      Tree 86 []
    ]
  ]

main : Element
main = let
    siblingDistance = 60
    levelHeight = 100
    padding = 40
  in
    draw siblingDistance
         levelHeight
         TreeLayout.TopToBottom
         padding
         drawPoint
         drawLine
         coolTree