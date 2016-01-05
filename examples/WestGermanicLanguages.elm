import Color exposing (..)
import Graphics.Collage exposing (..)
import Graphics.Element exposing (..)
import String
import Text

import TreeLayout exposing (draw, Tree(..), TreeLayout)


-- Tree to draw
westGermanicLanguages =
  Tree "West Germanic Languages" [
    Tree "Ingvaeonic" [
      Tree "Old Saxon" [
        Tree "Middle Low German" [
          Tree "Low German" []
        ]
      ],
      Tree "Anglo-Frisian" [
        Tree "Old English" [
          Tree "Middle English" [
            Tree "English" []
          ]
        ],
        Tree "Old Frisian" [
          Tree "Frisian" []
        ]
      ]
    ],
    Tree "Istvaeonic" [
      Tree "Old Dutch" [
        Tree "Middle Dutch" [
          Tree "Dutch" [],
          Tree "Afrikaans" []
        ]
      ]
    ],
    Tree "Irminonic" [
      Tree "Old High German" [
        Tree "Middle High German" [
          Tree "German" []
        ],
        Tree "Old Yiddish" [
          Tree "Yiddish" []
        ]
      ]
    ]
  ]


{-| Represent edges as straight lines.
-}
drawLine : (Float, Float) -> (Float, Float) -> Form
drawLine from to = segment from to |> traced (solid black)


{-| Represent nodes as circles with the node value inside.
-}
drawPoint : String -> Form
drawPoint n = let
    bubble = circle 16
  in
    group [
      bubble |> filled white,
      bubble |> outlined defaultLine,
      Text.fromString n |> Text.color black |> text
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
         westGermanicLanguages
