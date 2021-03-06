{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric #-}

module Distribution.Types.TestSuite (
    TestSuite(..),
    emptyTestSuite,
    testType,
    testModules,
) where

import Prelude ()
import Distribution.Compat.Prelude

import Distribution.Types.BuildInfo
import Distribution.Types.TestType
import Distribution.Types.TestSuiteInterface

import Distribution.ModuleName

-- | A \"test-suite\" stanza in a cabal file.
--
data TestSuite = TestSuite {
        testName      :: String,
        testInterface :: TestSuiteInterface,
        testBuildInfo :: BuildInfo
    }
    deriving (Generic, Show, Read, Eq, Typeable, Data)

instance Binary TestSuite

instance Monoid TestSuite where
    mempty = TestSuite {
        testName      = mempty,
        testInterface = mempty,
        testBuildInfo = mempty
    }
    mappend = (<>)

instance Semigroup TestSuite where
    a <> b = TestSuite {
        testName      = combine' testName,
        testInterface = combine  testInterface,
        testBuildInfo = combine  testBuildInfo
    }
        where combine   field = field a `mappend` field b
              combine' f = case (f a, f b) of
                        ("", x) -> x
                        (x, "") -> x
                        (x, y) -> error "Ambiguous values for test field: '"
                            ++ x ++ "' and '" ++ y ++ "'"

emptyTestSuite :: TestSuite
emptyTestSuite = mempty


testType :: TestSuite -> TestType
testType test = case testInterface test of
  TestSuiteExeV10 ver _         -> TestTypeExe ver
  TestSuiteLibV09 ver _         -> TestTypeLib ver
  TestSuiteUnsupported testtype -> testtype

-- | Get all the module names from a test suite.
testModules :: TestSuite -> [ModuleName]
testModules test = (case testInterface test of
                     TestSuiteLibV09 _ m -> [m]
                     _                   -> [])
                ++ otherModules (testBuildInfo test)
