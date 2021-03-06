module Main exposing (..)

import Color exposing (..)
import Collage exposing (..)
import Element exposing (..)
import Text exposing (..)
import TreeDiagram exposing (node, Tree, defaultTreeLayout)
import TreeDiagram.Canvas exposing (draw)


-- Tree to draw


coolTree : Tree Int
coolTree =
    node
        61
        [ node
            84
            [ node 22 []
            , node 38 []
            ]
        , node
            72
            [ node
                3
                [ node 59 []
                , node 29 []
                , node 54 []
                ]
            , node 25 []
            , node 49 []
            ]
        , node
            24
            [ node 2 []
            ]
        , node
            17
            [ node 26 []
            , node
                68
                [ node 13 []
                , node 36 []
                ]
            , node 86 []
            ]
        ]


{-| Represent edges as straight lines.
-}
drawLine : ( Float, Float ) -> Form
drawLine to =
    segment ( 0, 0 ) to |> traced (solid black)


{-| Represent nodes as circles with the node value inside.
-}
drawNode : Int -> Form
drawNode n =
    group
        [ circle 16 |> filled white
        , circle 16 |> outlined defaultLine
        , toString n |> fromString |> Text.color black |> text
        ]


main =
    Element.toHtml <|
        draw defaultTreeLayout drawNode drawLine coolTree
