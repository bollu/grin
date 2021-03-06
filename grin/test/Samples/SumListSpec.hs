{-# LANGUAGE OverloadedStrings, QuasiQuotes, ViewPatterns #-}
module Samples.SumListSpec where

import Pipeline.Pipeline

import Test.Hspec
import Grin.TH
import Test.Test hiding (newVar)
import Test.Assertions

runTests :: IO ()
runTests = hspec spec

spec :: Spec
spec = do
  it "lazy list sum - half pipeline" $ do
    let before = [prog|
        grinMain =
          p1 <- store (CInt 0)
          p2 <- store (CInt 1)
          p3 <- store (CInt 1000)
          p4 <- store (Fupto p2 p3)
          p5 <- store (Fsum p1 p4)
          (Fsum p15 p16) <- fetch p5
          n13' <- sum p15 p16
          _prim_int_print n13'

        sum p10 p11 =
          (Fupto p17 p18) <- fetch p11
          p6 <- pure p17
          p7 <- pure p18
          (CInt n2') <- fetch p6
          (CInt n3') <- fetch p7
          b1' <- _prim_int_gt n2' n3'
          do
            case b1' of
              #True ->
                v10_1 <- pure (CNil)
                case v10_1 of
                  (CNil) ->
                    (CInt n14') <- fetch p10
                    pure n14'
                  (CCons p12 p13) ->
                    (CInt n5') <- fetch p10
                    (CInt n6') <- fetch p12
                    n7' <- _prim_int_add n5' n6'
                    p14 <- store (CInt n7')
                    sum p14 p13
              #False ->
                n4' <- _prim_int_add n2' 1
                p8 <- store (CInt n4')
                p9 <- store (Fupto p8 p7)
                v10_2 <- pure (CCons p6 p9)
                case v10_2 of
                  (CNil) ->
                    (CInt n14'_2) <- fetch p10
                    pure n14'_2
                  (CCons p12_2 p13_2) ->
                    (CInt n5'_2) <- fetch p10
                    (CInt n6'_2) <- fetch p12_2
                    n7'_2 <- _prim_int_add n5'_2 n6'_2
                    p14_2 <- store (CInt n7'_2)
                    sum p14_2 p13_2
      |]
    let after = [prog|
        grinMain =
          n13' <- sum 0 1 1000
          _prim_int_print n13'

        sum p10 p111 p112 =
          b1' <- _prim_int_gt p111 p112
          case b1' of
            #True ->
              pure p10
            #False ->
              n4' <- _prim_int_add p111 1
              n7'_2 <- _prim_int_add p10 p111
              sum n7'_2 n4' p112
      |]
    let ppln =
          [ Pass [HPT CompileHPT, HPT RunHPTPure]
          , T BindNormalisation
          , T ConstantPropagation
          , T BindNormalisation
          , T CommonSubExpressionElimination
          , T CopyPropagation
          , T DeadVariableElimination
          , T ArityRaising
          , T CopyPropagation
          , T DeadVariableElimination
          , T ArityRaising
          , T CopyPropagation
          , T DeadVariableElimination
          ]

    (pipelineInfo, transformed) <- pipeline defaultOpts before ppln
    transformed `sameAs` after
