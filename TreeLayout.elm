module TreeLayout (draw, layout, Tree(Tree)) where

import Debug
import Graphics.Collage exposing (..)
import Graphics.Element exposing (..)

type Tree a = Tree a (List (Tree a))

type alias Coord = (Float, Float)
type alias Contour = List (Int, Int)
type alias PointDrawer a = a -> Form
type alias LineDrawer = Coord -> Coord -> Form
type alias CoordTransform = Coord -> Coord
type alias PrelimPosition = {
  subtreeOffset: Int,
  rootOffset: Int }


{-| Public function for drawing a tree.
    In addition to a few positioning parameters, this function takes a tree, a
    line drawing function, and a node drawing function. It determines the layout
    for the tree and uses the provided drawing functions to create a visual
    represntation of the tree.
-}
draw : Int -> Int -> Int -> PointDrawer a -> LineDrawer -> Tree a -> Element
draw siblingDistance levelHeight padding drawPoint drawLine tree =
  let
    positionedTree = layout siblingDistance levelHeight tree
  in
    drawPositioned padding drawPoint drawLine positionedTree


{-| Helper function for recursively drawing the tree.
-}
drawInternal : Int
            -> CoordTransform
            -> PointDrawer a
            -> LineDrawer
            -> Tree (a, Coord)
            -> List Form
drawInternal padding
             transformCoord
             drawPoint
             drawLine
             (Tree (v, coord) subtrees) =
  let
    (transformedX, transformedY) = transformCoord coord
    paddedCoord = (transformedX + toFloat padding,
                   transformedY + toFloat padding)
    subtreePositions = List.map (\ (Tree (_, coord) _) -> transformCoord coord)
                                subtrees
    rootDrawing = drawPoint v |> move paddedCoord
    edgeDrawings = List.map (drawLine paddedCoord) subtreePositions
  in
    List.append (List.append edgeDrawings [rootDrawing])
                (List.concatMap (drawInternal padding
                                              transformCoord
                                              drawPoint
                                              drawLine)
                                subtrees)


{-| Public function for assigning the positions of a tree's nodes.
    The value returned by this function is a tuple of the positioned tree, and
    the dimensions the tree occupied by the positioned tree.
-}
layout : Int -> Int -> Tree a -> Tree (a, Coord)
layout siblingDistance levelHeight tree = let
    (prelimTree, _) = prelim siblingDistance tree
  in
    final 0 levelHeight 0 prelimTree


{-| Public function for drawing an already-positioned tree.
    This function will probably be used in conjunction with `layout`. It is
    useful in situations where you want to make some ad-hoc changes to the node
    positions assigned by the layout function prior to drawing the tree, or you
    want to embelish the tree with some extra drawings prior to proceeding with
    the normal drawing process.
-}
drawPositioned : Int
              -> PointDrawer a
              -> LineDrawer
              -> Tree (a, Coord)
              -> Element
drawPositioned padding drawPoint drawLine positionedTree = let
    (width, height) = Debug.log "bounding box:" <| treeBoundingBox positionedTree
    coordTransform = (\ (x, y) -> (x - width / 2, -y + height / 2))
  in
    collage (round width + 2 * padding)
            (round height + 2 * padding)
            (drawInternal 0 --TODO
                          coordTransform
                          drawPoint
                          drawLine
                          positionedTree)


{-| Finds the smallest box that fits around the given positioned tree
-}
treeBoundingBox : Tree (a, Coord) -> (Float, Float)
treeBoundingBox (Tree (_, (x, y)) subtrees) = let
    extrema = List.map treeBoundingBox subtrees
    (maxXs, maxYs) = List.unzip extrema
  in
    (Maybe.withDefault x <| List.maximum maxXs,
      Maybe.withDefault y <| List.maximum maxYs)


{-| Assign the final position of each node within the the input tree. The final
    positions are found by performing a preorder traversal of the tree and
    summing up the relative positions of each node's ancestors as the traversal
    moves down the tree.
-}
final : Int
     -> Int
     -> Int
     -> Tree (a, PrelimPosition)
     -> Tree (a, Coord)
final level
      levelHeight
      lOffset
      (Tree (v, prelimPosition) subtrees) =
  let
    finalPosition = (toFloat (lOffset + prelimPosition.rootOffset),
                     toFloat (level * levelHeight))

    -- Preorder recursal into child trees
    subtreePrelimPositions = List.map
      (\ (Tree (_, prelimPosition) _) -> prelimPosition)
      subtrees
    visited = List.map2
      (\ prelimPos subtree -> final (level + 1)
                                    levelHeight
                                    (lOffset + prelimPos.subtreeOffset)
                                    subtree)
      subtreePrelimPositions
      subtrees
  in
    Tree (v, finalPosition) visited


{-| Assign the preliminary position of each node within the input tree. The
    preliminary positions are found by performing a postorder traversal on the
    tree and aligning each subtree relative to its parent. Sibling subtrees are
    pushed together as close to each other as possible, and parent nodes are
    positioned so that they're centered over their children.
-}
prelim : Int -> Tree a -> (Tree (a, PrelimPosition), Contour)
prelim siblingDistance (Tree val children) = let

    -- Traverse each of the subtrees, getting the positioned subtree as well as
    -- a description of its contours.
    visited = List.map (prelim siblingDistance) children
    (subtrees, childContours) = List.unzip visited

    -- Calculate the position of the left bound of each subtree, relative to
    -- the left bound of the current tree.
    offsets = subtreeOffsets siblingDistance childContours

    -- Store the offset for each of the subtrees.
    updatedChildren = List.map2
      (\ (Tree (v, prelimPosition) children) offset ->
        Tree (v, { prelimPosition | subtreeOffset = offset }) children)
      subtrees
      offsets
  in
    case ends <| List.map2 (,) updatedChildren childContours of

      -- The root of the current tree has children.
      Just ((lSubtree, lSubtreeContour), (rSubtree, rSubtreeContour)) ->
        let
          (Tree (_, lPrelimPos) _) = lSubtree
          (Tree (_, rPrelimPos) _) = rSubtree

          -- Calculate the position of the root, relative to the left bound of
          -- the current tree. Store this in the preliminary position for the
          -- current tree.
          prelimPos = {
            subtreeOffset = 0,
            rootOffset = rootOffset lPrelimPos rPrelimPos
          }

          -- Construct the contour description of the current tree.
          rootContour = (prelimPos.rootOffset, prelimPos.rootOffset)
          treeContour = rootContour::(buildContour lSubtreeContour
                                                   rSubtreeContour
                                                   rPrelimPos.subtreeOffset)
        in
          (Tree (val, prelimPos) updatedChildren, treeContour)

      -- The root of the current tree is a leaf node.
      Nothing ->
        (Tree (val, {subtreeOffset = 0, rootOffset = 0}) updatedChildren,
          [(0, 0)])


{-| Given the preliminary positions of leftmost and rightmost subtrees, this
    calculates the offset of the root (their parent) relative to the leftmost
    bound of the tree starting at the root.
-}
rootOffset : PrelimPosition -> PrelimPosition -> Int
rootOffset lPrelimPosition rPrelimPosition =
  (lPrelimPosition.subtreeOffset +
   rPrelimPosition.subtreeOffset +
   lPrelimPosition.rootOffset +
   rPrelimPosition.rootOffset) // 2


{-| Calculate how far each subtree should be offset from the left bound of the
    first (leftmost) subtree. Each subtree needs to be positioned so that it is
    exactly `siblingDistance` away from its neighbors.
-}
subtreeOffsets : Int -> List Contour -> List Int
subtreeOffsets siblingDistance contours = case List.head contours of
  Just c0 -> let
    cumulativeContours = List.scanl
      (\ c (aggContour, _) -> let
          offset = pairwiseSubtreeOffset siblingDistance aggContour c
        in
          (buildContour aggContour c offset, offset))
      (c0, 0)
      (List.drop 1 contours)
    in
      List.map (\ (_, runningOffset) -> runningOffset) cumulativeContours
  Nothing -> []


{-| Given two contours, calculate the offset of the second from the left bound
    of the first such that the two are separated by exactly `siblingDistance`.
-}
pairwiseSubtreeOffset : Int -> Contour -> Contour -> Int
pairwiseSubtreeOffset siblingDistance lContour rContour = let
    levelDistances = List.map2 (\ (_, lTo) (rFrom, _) -> lTo - rFrom)
                               lContour
                               rContour
  in
    case List.maximum levelDistances of
      Just separatingDistance -> separatingDistance + siblingDistance
      Nothing -> 0


{-| Construct a contour for a tree. This is done by combining together the
    contours of the leftmost and rightmost subtrees, and then adding the root
    at the top of the new contour.
-}
buildContour : Contour -> Contour -> Int -> Contour
buildContour lContour rContour rContourOffset = let
    lLength = List.length lContour
    rLength = List.length rContour
    combinedContour = List.map2 (\ (lFrom, lTo) (rFrom, rTo) ->
      (lFrom, rTo + rContourOffset)) lContour rContour
  in
    if lLength > rLength then
      List.append combinedContour (List.drop rLength lContour)
    else
      List.append combinedContour (List.map
        (\ (from, to) -> (from + rContourOffset, to + rContourOffset))
        (List.drop lLength rContour))


{-| Create a tuple containing the first and last elements in a list

    ends [1, 2, 3, 4] == (1, 4)
-}
ends : List a -> Maybe (a, a)
ends list = let
    first = List.head list
    last = List.head <| List.reverse list
  in
    Maybe.map2 (\ a b -> (a, b)) first last
