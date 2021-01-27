
class PerformanceTests
{
    function run()
    {
        local output1 = "", output2 = "", output3 = "";
        output1  = "Running Performance Tests\n";
        output1 += "=========================\n";
        
        output1 += nullVsImpliedComparison(); collectgarbage();
        output1 += newSlotVsSet(); collectgarbage();
        output1 += cloneVsNewArray(); collectgarbage();
        output1 += appendArrayVsSetPreallocatedArray(); collectgarbage();
        output1 += arrayAppendVsArrayPush(); collectgarbage();
        output2 += ifVsRegexpTypeof(); collectgarbage();
        output2 += switchStatementVsTableLookup(); collectgarbage();
        output2 += tryVsIn(); collectgarbage();
        output2 += noKeyVsDelegateMetamethod(); collectgarbage();
        output2 += localVsTwoTableLookup(); collectgarbage();
        output2 += loopVsCachedLoop(); collectgarbage();
        output3 += foreachVsForVsWhileLoop(); collectgarbage();
        output3 += classVsStaticClass(); collectgarbage();
        output3 += bracketsVsNoBrackets(); collectgarbage();
        output3 += LookupVsTypeCheckComparison(); collectgarbage();
        output3 += regexpVsStringFind(); collectgarbage();
        output3 += singleVsMultipleClosures(); collectgarbage();

        server.log( output1 );
        server.log( output2 );
        server.log( output3 );
    }

    /// Tests to see if it's faster to:
    /// A. Compare a value to null via '== null'
    /// B. Inspect the value directly for its truthyness
    function nullVsImpliedComparison()
    {
        local myValue = null;

        local time1 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            if( myValue == null );
        }
        local time2 = hardware.micros();

        local time3 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            if( myValue );
        }
        local time4 = hardware.micros();

        local time5 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            if( myValue != null );
        }
        local time6 = hardware.micros();

        local time7 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            if( !myValue );
        }
        local time8 = hardware.micros();

        local controlTime1 = hardware.micros();
        for( local i = 0; i < 100000; ++i ) {}
        local controlTime2 = hardware.micros();
        local controlTime = controlTime2 - controlTime1;

        return _printResults( "Null Comparison vs Direct Truthy Comparison (x100,000)",
        [
            [ "Null equals comparison", time2 - time1 - controlTime ],
            [ "Direct truthy comparison", time4 - time3 - controlTime ],
            [ "Null not equals comparison", time6 - time5 - controlTime ],
            [ "Direct falsey comparison", time8 - time7 - controlTime ]
        ]);
    }

    /// Tests to see if it's faster to:
    /// A. Use a separate VM instruction for new slot.
    /// B. Use an if statement to determine whether to use Set or New Slot.
    /// Results were surprising, NewSlot was faster in all instances! Suggesting we don't
    /// need to support a NewSlot operator for tables. However array doesn't support NewSlot.
    function newSlotVsSet()
    {
        local myTable = { myVar = 0 };

        local time1 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            myTable.myVar = 0;
        }
        local time2 = hardware.micros();

        local time3 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            myTable.myVar <- 0;
        }
        local time4 = hardware.micros();

        local time5 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            myTable.rawset( "myVar", 0 );
        }
        local time6 = hardware.micros();

        local time7 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            if( "myVar" in myTable ) { myTable.myVar = 0; }
            else { myTable.myVar <- 0; }
        }
        local time8 = hardware.micros();

        local controlTime1 = hardware.micros();
        for( local i = 0; i < 100000; ++i ) {}
        local controlTime2 = hardware.micros();
        local controlTime = controlTime2 - controlTime1;

        return _printResults( "NewSlot vs Set vs Rawset (x100,000)",
        [
            [ "Using Set only", time2 - time1 - controlTime ],
            [ "Using NewSlot only", time4 - time3 - controlTime ],
            [ "Using Rawset only", time6 - time5 - controlTime ],
            [ "If statement to determine NewSlot vs Set", time8 - time7 - controlTime ]
        ]);
    }

    /// Tests to see if it's faster to:
    /// A. Use NewArray to popule an array with the same values.
    /// B. Use clone to populate an array with the same values.
    /// Results show clone to be slightly faster.
    function cloneVsNewArray()
    {
        local myArray = [0, "test"];
        local newArray;

        local time1 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            newArray = [myArray[0], myArray[1]];
        }
        local time2 = hardware.micros();

        newArray = null;
        collectgarbage();
        newArray = [];

        local time3 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            newArray = clone myArray;
        }
        local time4 = hardware.micros();

        local controlTime1 = hardware.micros();
        for( local i = 0; i < 100000; ++i ) {}
        local controlTime2 = hardware.micros();
        local controlTime = controlTime2 - controlTime1;

        return _printResults( "Clone vs NewArray (x100,000)",
        [
            [ "Using NewArray", time2 - time1 - controlTime ],
            [ "Using Clone", time4 - time3 - controlTime ]
        ]);
    }

    /// Tests to see if it's faster to:
    /// A. Append values to an empty array.
    /// B. Set values in a preallocated array.
    /// Results show preallocation significantly faster, however difference
    /// becomes much negligible for smaller arrays
    function appendArrayVsSetPreallocatedArray()
    {
        local time1 = hardware.micros();
        local newArray = [];
        for( local i = 0; i < 50000; ++i )
        {
            newArray.append( 100 );
        }
        local time2 = hardware.micros();

        newArray = null;
        collectgarbage();

        local time3 = hardware.micros();
        newArray = array( 50000 );
        for( local i = 0; i < 50000; ++i )
        {
            newArray[i] = 100;
        }
        local time4 = hardware.micros();

        local controlTime1 = hardware.micros();
        for( local i = 0; i < 50000; ++i ) {}
        local controlTime2 = hardware.micros();
        local controlTime = controlTime2 - controlTime1;

        return _printResults( "Append Array vs Set Preallocated Array (x50,000)",
        [
            [ "Using Append", time2 - time1 - controlTime ],
            [ "Using Preallocated Set", time4 - time3 - controlTime ]
        ]);
    }

    /// Tests to see if it's faster to:
    /// A. Append values to an array.
    /// B. Push values to an array.
    /// No significant difference.
    function arrayAppendVsArrayPush()
    {
        local newArray = [];

        local time1 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            newArray.append( 100 );
        }
        local time2 = hardware.micros();

        newArray = null;
        collectgarbage();
        newArray = [];

        local time3 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            newArray.push( 100 );
        }
        local time4 = hardware.micros();

        local controlTime1 = hardware.micros();
        for( local i = 0; i < 100000; ++i ) {}
        local controlTime2 = hardware.micros();
        local controlTime = controlTime2 - controlTime1;

        return _printResults( "Array Append vs Array Push (x100,000)",
        [
            [ "Using Append", time2 - time1 - controlTime ],
            [ "Using Push", time4 - time3 - controlTime ]
        ]);
    }

    /// Tests to see if it's faster to:
    /// A. Use typeof in an if statement multiple times to check multiple types
    /// B. Use typeof once, save locally and use in an if statement multiple times to check multiple types
    /// C. Use typeof once and use a regular expression
    /// Results show regular expressions to be quickest.
    function ifVsRegexpTypeof()
    {
        local myTable = { myVar = 0 };

        local time1 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            if( typeof(myTable) != "integer" && typeof(myTable) != "float" && typeof(myTable) != "string" && typeof(myTable) != "bool" && typeof(myTable) != "null" )
            {}
        }
        local time2 = hardware.micros();

        local time3 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            local myTableType = typeof(myTable);
            if( myTableType != "integer" && myTableType != "float" && myTableType != "string" && myTableType != "bool" && myTableType != "null" )
            {}
        }
        local time4 = hardware.micros();
        
        local isBaseType = regexp( @"integer|float|string|bool|null" );
        
        local time5 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
           if( isBaseType.match( typeof(myTable) ) ) {}
        }
        local time6 = hardware.micros();

        local controlTime1 = hardware.micros();
        for( local i = 0; i < 100000; ++i ) {}
        local controlTime2 = hardware.micros();
        local controlTime = controlTime2 - controlTime1;

        return _printResults( "If vs Regexp for 5x Typeof comparisions (x100,000)",
        [
            [ "Using if comparison", time2 - time1 - controlTime ],
            [ "Using cached if comparison", time4 - time3 - controlTime ],
            [ "Using regexp", time6 - time5 - controlTime ]
        ]);
    }

    function switchStatementVsTableLookup()
    {
        local action = function() { return 10 + 5; };

        local valuesEven    = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29];
        local valuesBottom  = [0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3,0,1];
        local valuesTop     = [26,27,28,29,26,27,28,29,26,27,28,29,26,27,28,29,26,27,28,29,26,27,28,29,26,27,28,29,26,27];
        local valuesSparse  = [1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000];

        local lookupTable = {};

        for( local i = 0; i < 30; ++i )
        {
            lookupTable[i] <- action;
        }

        local lookupTableSparse = clone lookupTable;
        lookupTableSparse[1000] <- action;

        local lookupArray = array( 30, action );
        local lookupArraySparse = array( 1001, action );

        local tableLookup = function( values )
        {
            local time1 = hardware.micros();
            for( local i = 0; i < 10000; ++i )
            {
                foreach( value in values )
                {
                    lookupTable[value]();
                }
            }
            local time2 = hardware.micros();

            return time2 - time1;
        };

        local tableSparseLookup = function( values )
        {
            local time1 = hardware.micros();
            for( local i = 0; i < 10000; ++i )
            {
                foreach( value in values )
                {
                    lookupTableSparse[value]();
                }
            }
            local time2 = hardware.micros();

            return time2 - time1;
        };

        local arrayLookup = function( values )
        {
            local time1 = hardware.micros();
            for( local i = 0; i < 10000; ++i )
            {
                foreach( value in values )
                {
                    lookupArray[value]();
                }
            }
            local time2 = hardware.micros();

            return time2 - time1;
        };

        local arraySparseLookup = function( values )
        {
            local time1 = hardware.micros();
            for( local i = 0; i < 10000; ++i )
            {
                foreach( value in values )
                {
                    lookupArraySparse[value]();
                }
            }
            local time2 = hardware.micros();

            return time2 - time1;
        };
 
        local switchLookup = function( values )
        {
            local result;
            local time1 = hardware.micros();
            for( local i = 0; i < 10000; ++i )
            {
                foreach( value in values )
                {
                    switch( value )
                    {
                        case 0: action(); break; case 1: action(); break; case 2: action(); break; case 3: action(); break; case 4: action(); break;
                        case 5: action(); break; case 6: action(); break; case 7: action(); break; case 8: action(); break; case 9: action(); break;
                        case 10: action(); break; case 11: action(); break; case 12: action(); break; case 13: action(); break; case 14: action(); break;
                        case 15: action(); break; case 16: action(); break; case 17: action(); break; case 18: action(); break; case 19: action(); break;
                        case 20: action(); break; case 21: action(); break; case 22: action(); break; case 23: action(); break; case 24: action(); break;
                        case 25: action(); break; case 26: action(); break; case 27: action(); break; case 28: action(); break; case 29: action(); break;
                        default: break;
                    }
                }
            }
            local time2 = hardware.micros();

            return time2 - time1;
        };

        local switchSparseLookup = function( values )
        {
            local time1 = hardware.micros();
            for( local i = 0; i < 10000; ++i )
            {
                foreach( value in values )
                {
                    switch( value )
                    {
                        case 0: action(); break; case 1: action(); break; case 2: action(); break; case 3: action(); break; case 4: action(); break;
                        case 5: action(); break; case 6: action(); break; case 7: action(); break; case 8: action(); break; case 9: action(); break;
                        case 10: action(); break; case 11: action(); break; case 12: action(); break; case 13: action(); break; case 14: action(); break;
                        case 15: action(); break; case 16: action(); break; case 17: action(); break; case 18: action(); break; case 19: action(); break;
                        case 20: action(); break; case 21: action(); break; case 22: action(); break; case 23: action(); break; case 24: action(); break;
                        case 25: action(); break; case 26: action(); break; case 27: action(); break; case 28: action(); break; case 29: action(); break;
                        case 1000: action(); break;
                        default: break;
                    }
                }
            }
            local time2 = hardware.micros();

            return time2 - time1;
        };

        local result1 = switchLookup( valuesEven );
        local result2 = switchLookup( valuesBottom );
        local result3 = switchLookup( valuesTop );
        local result4 = tableLookup( valuesEven );
        local result5 = tableLookup( valuesBottom );
        local result6 = tableLookup( valuesTop );
        local result7 = arrayLookup( valuesEven );
        local result8 = arrayLookup( valuesBottom );
        local result9 = arrayLookup( valuesTop );
        local result10 = switchSparseLookup( valuesSparse );
        local result11 = tableSparseLookup( valuesSparse );
        local result12 = arraySparseLookup( valuesSparse );

        local controlTime1 = hardware.micros();
        for( local i = 0; i < 10000; ++i ) {}
        local controlTime2 = hardware.micros();
        local controlTime = controlTime2 - controlTime1;

        return _printResults( "Switch Statement vs Table Lookup vs Array Lookup (x10,000)",
        [
            [ "Switch Lookup (even)", result1 - controlTime  ],
            [ "Switch Lookup (bottom)", result2 - controlTime ],
            [ "Switch Lookup (top)", result3 - controlTime ],
            [ "Table Lookup (even)", result4 - controlTime ],
            [ "Table Lookup (bottom)", result5 - controlTime ],
            [ "Table Lookup (top)", result6 - controlTime ],
            [ "Array Lookup (even)", result7 - controlTime ],
            [ "Array Lookup (bottom)", result8 - controlTime ],
            [ "Array Lookup (top)", result9 - controlTime ],
            [ "Switch Sparse Lookup", result10 - controlTime ],
            [ "Table Sparse Lookup", result11 - controlTime ],
            [ "Array Sparse Lookup", result12 - controlTime ],
        ]);
    }

    /// Tests to see if it's faster to:
    /// A. Use a try to determine if a key exists.
    /// B. Use the keyword 'in' to determine if a key exists.
    function tryVsIn()
    {
        local MyClass   = class { function myTestFunction() {} };
        local MyClass2  = class { function someOtherFunction() {} };
        local myClass   = MyClass();
        local myClass2  = MyClass2();
        local element   = "myTestFunction";

        local time1 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            try { myClass[element]; } catch( error ) {}
        }
        local time2 = hardware.micros();

        local time3 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            try { myClass2[element]; } catch( error ) {}
        }
        local time4 = hardware.micros();

        local time5 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            if( element in MyClass ) { }
        }
        local time6 = hardware.micros();

        local time7 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            if( element in MyClass2 ) { }
        }
        local time8 = hardware.micros();

        local controlTime1 = hardware.micros();
        for( local i = 0; i < 100000; ++i ) {}
        local controlTime2 = hardware.micros();
        local controlTime = controlTime2 - controlTime1;

        return _printResults( "Try vs In (x100,000)",
        [
            [ "Using Try when key exists", time2 - time1 - controlTime ],
            [ "Using Try when key doesn't exist", time4 - time3 - controlTime ],
            [ "Using In when key exists", time6 - time5 - controlTime ],
            [ "Using In when key doesn't exist", time8 - time7 - controlTime ]
        ]);
    }

    /// Tests to see if it's faster to:
    /// A. Check for key presence in a table.
    /// B. Access the key using a delegate metamethod.
    function noKeyVsDelegateMetamethod()
    {
        local testTable     = {};
        local delegateTable =
        {
            _get = function( key )
            {
                return {};
            }
        }
        testTable.setdelegate( delegateTable );

        local someVariable = 0;

        local time1 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
           if( "testKey" in testTable ) {}
        }
        local time2 = hardware.micros();

        local time3 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            testTable["testKey"];
        }
        local time4 = hardware.micros();

        local controlTime1 = hardware.micros();
        for( local i = 0; i < 100000; ++i ) {}
        local controlTime2 = hardware.micros();
        local controlTime = controlTime2 - controlTime1;

        return _printResults( "No Table Key vs Table Delegate Metamethod (x100,000)",
        [
            [ "Checking for key presence", time2 - time1 - controlTime ],
            [ "Accessing the key using a delegate metamethod", time4 - time3 - controlTime ]
        ]);
    }

    /// Tests to see if it's faster to:
    /// A. Use a local to cache table variable lookups for two+ lookups.
    /// B. Lookup the table variable directly twice.
    function localVsTwoTableLookup()
    {
        local testTable = { testKey = 100000 };

        local time1 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            local cachedTestKey = testTable.testKey;
            cachedTestKey;
            cachedTestKey;
        }
        local time2 = hardware.micros();

        local time3 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            testTable.testKey;
            testTable.testKey;
        }
        local time4 = hardware.micros();

        local controlTime1 = hardware.micros();
        for( local i = 0; i < 100000; ++i ) {}
        local controlTime2 = hardware.micros();
        local controlTime = controlTime2 - controlTime1;

        return _printResults( "Local vs Two Table Lookup (x100,000)",
        [
            [ "Using local", time2 - time1 - controlTime ],
            [ "Using direct lookup", time4 - time3 - controlTime ]
        ]);
    }

    /// Tests to see if it's faster to:
    /// A. Use a loop comparing against an uncached table key.
    /// B. Use a loop comparing against a cached table key.
    function loopVsCachedLoop()
    {
        local testTable = { testKey = 50000 };

        local time1 = hardware.micros();
        for( local i = 0; i < testTable.testKey; ++i );
        local time2 = hardware.micros();

        local testKey = testTable.testKey;

        local time3 = hardware.micros();
        for( local i = 0; i < testKey; ++i );
        local time4 = hardware.micros();

        local testTable2 = { testKey = array(50000) };

        local time5 = hardware.micros();
        foreach( index, value in testTable2.testKey );
        local time6 = hardware.micros();

        local testKey2 = testTable2.testKey;

        local time7 = hardware.micros();
        foreach( index, value in testKey2 );
        local time8 = hardware.micros();

        return _printResults( "Empty Loop vs Empty Cached Loop (x50,000)",
        [
            [ "Using uncached loop", time2 - time1 ],
            [ "Using cached loop", time4 - time3 ],
            [ "Using uncached foreach loop", time6 - time5 ],
            [ "Using cached foreach loop", time8 - time7 ]
        ]);
    }

    /// Tests to see if it's faster to:
    /// A. Use a foreach loop.
    /// B. Use a cached for loop.
    /// B. Use a cached while loop.
    function foreachVsForVsWhileLoop()
    {
        local testArray     = array( 50000 );
        local testArraySize = testArray.len();

        local time1 = hardware.micros();
        foreach( element in testArray ) { element; };
        local time2 = hardware.micros();

        local time3 = hardware.micros();
        for( local i = 0; i < testArraySize; ++i ) { testArray[i]; }
        local time4 = hardware.micros();

        local i = -1;

        local time5 = hardware.micros();
        while( ++i < testArraySize ) { testArray[i]; }
        local time6 = hardware.micros();

        return _printResults( "Foreach Loop vs Cached For Loop vs Cached While Loop (x50,000)",
        [
            [ "Using a foreach loop", time2 - time1 ],
            [ "Using a cached for loop", time4 - time3 ],
            [ "Using a cached while loop", time6 - time5 ]
        ]);
    }

    /// Tests to see if it's faster to:
    /// A. Use a class instance.
    /// B. Use a static class.
    function classVsStaticClass()
    {
        local TestClass = class
        {
            testAttribute = 10;
            function testFunction()
            {
                testAttribute = testAttribute + 1;
            }
        }

        local TestStaticClass = class
        {
            static testAttribute = 10;
            static function testFunction()
            {
                testAttribute <- testAttribute + 1;
            }
        }

        local testClass = TestClass();

        local time1 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            testClass.testAttribute = testClass.testAttribute + 1;
            testClass.testFunction();
        }
        local time2 = hardware.micros();

        local time3 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            TestStaticClass.testAttribute <- TestStaticClass.testAttribute + 1;
            TestStaticClass.testFunction();
        }
        local time4 = hardware.micros();

        local controlTime1 = hardware.micros();
        for( local i = 0; i < 100000; ++i ) {}
        local controlTime2 = hardware.micros();
        local controlTime = controlTime2 - controlTime1;

        return _printResults( "Class vs Static Class (x100,000)",
        [
            [ "Using a class instance", time2 - time1 - controlTime ],
            [ "Using a static class", time4 - time3 - controlTime ]
        ]);
    }

    /// Tests to see if it's faster to:
    /// A. Use brackets after a statement.
    /// B. Use no brackets after a statement.
    function bracketsVsNoBrackets()
    {
        local someVariable = 0;

        local time1 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
           if( true ) { ++someVariable; }
        }
        local time2 = hardware.micros();

        someVariable = 0;

        local time3 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            if( true ) ++someVariable;
        }
        local time4 = hardware.micros();

        someVariable = 0;

        local time5 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            if( false ) { ++someVariable; }
            else { ++someVariable; }
        }
        local time6 = hardware.micros();

        someVariable = 0;

        local time7 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            if( false ) ++someVariable;
            else ++someVariable;
        }
        local time8 = hardware.micros();

        local controlTime1 = hardware.micros();
        for( local i = 0; i < 100000; ++i ) {}
        local controlTime2 = hardware.micros();
        local controlTime = controlTime2 - controlTime1;

        return _printResults( "Brackets vs No Brackets (x100,000)",
        [
            [ "Using brackets after an if statement", time2 - time1 - controlTime ],
            [ "Using no brackets after an if statement", time4 - time3 - controlTime ],
            [ "Using brackets after an if/else statement", time6 - time5 - controlTime ],
            [ "Using no brackets after an if/else statement", time8 - time7 - controlTime ]
        ]);
    }

    /// Tests to see if it's faster to:
    /// A. Search for a value in two tables, when the value is in the second table
    /// B. Search for a value in one table then extract and verify the type from an array
    /// C. Search for the value in one table then extract and verify its type from the same table
    function LookupVsTypeCheckComparison()
    {
        local testTable1 =
        {
            testValue1 = ["integer",1],
            testValue2 = ["integer",2],
            testValue3 = ["integer",3],
            testValue4 = ["integer",4],
            testValue5 = ["integer",5],
            testValue6 = ["integer",6],
            testValue7 = ["integer",7]
        };

        local testTable2 =
        {
            testValue8  = ["integer",8],
            testValue9  = ["integer",9],
            testValue10 = ["integer",10],
            testValue11 = ["integer",11],
            testValue12 = ["integer",12],
            testValue13 = ["integer",13],
            testValue14 = ["integer",14]
        };

        testTable2["*type*testValue11"] <- "integer";

        local searchValue = "testValue11";

        local time1 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            if( searchValue in testTable1 ) {}

            if( searchValue in testTable2 )
            {
                local retrievedValue = testTable2[searchValue];
            }
        }
        local time2 = hardware.micros();

        local time3 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            if( searchValue in testTable2 )
            {
                local retrievedValue = testTable2[searchValue];
                if( typeof(retrievedValue[0]) == "integer" )
                {
                    retrievedValue[1];
                }
            }
        }
        local time4 = hardware.micros();

        local time5 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            if( searchValue in testTable2 )
            {
                local retrievedValue = testTable2[searchValue];
                
                if( "*type*" + testTable2[searchValue] == "integer" )
                {
                }
            }
        }
        local time6 = hardware.micros();

        local controlTime1 = hardware.micros();
        for( local i = 0; i < 100000; ++i ) {}
        local controlTime2 = hardware.micros();
        local controlTime = controlTime2 - controlTime1;

        return _printResults( "Lookup Separate Tables Comparison vs Lookup then Type Check Comparison (x100,000)",
        [
            [ "Value in two tables, when the value is in the second table comparison", time2 - time1 - controlTime ],
            [ "Value in one table then extract and verify the type from an array comparison", time4 - time3 - controlTime ],
            [ "Value in one table then extract and verify its type from the same table comparison", time6 - time5 - controlTime ]
        ]);
    }

    /// Tests to see if it's faster to:
    /// A. Search for a match at the strat of a string with a regexp
    /// B. Search for a match at the strat of a string with a simple regexp
    /// B. Search for a match at the strat of a string with a string find
    function regexpVsStringFind()
    {
        local myRegexp  = regexp( @"^__\w+" );
        local mySimpleRegexp  = regexp( @"^__.+" );
        local myValue   = "__";

        local testVariable  = "__hiThereImATest";
        local testVariable2 = "_hiThereImAFailedTest";

        local time1 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            if( myRegexp.match(testVariable) );
            if( myRegexp.match(testVariable2) );
        }
        local time2 = hardware.micros();

        local time3 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            if( mySimpleRegexp.match(testVariable) );
            if( mySimpleRegexp.match(testVariable2) );
        }
        local time4 = hardware.micros();

        local time5 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            if( testVariable.find("__") == 0 );
            if( testVariable2.find("__") == 0 );
        }
        local time6 = hardware.micros();

        local controlTime1 = hardware.micros();
        for( local i = 0; i < 100000; ++i ) {}
        local controlTime2 = hardware.micros();
        local controlTime = controlTime2 - controlTime1;

        return _printResults( "Regexp vs String find Comparison (x100,000)",
        [
            [ "Regexp comparison", time2 - time1 - controlTime ],
            [ "Simple regexp comparison", time4 - time3 - controlTime ],
            [ "String find comparison", time6 - time5 - controlTime ]
        ]);
    }

    /// Tests to see if it's faster to:
    /// A. Create and reuse a single closure
    /// B. Create multiple identical closures
    function singleVsMultipleClosures()
    {
        local testData = 0;

        local time1 = hardware.micros();
        local testClosure = function() { local captureSomething = testData; return captureSomething; }.bindenv(this);
        local time2 = hardware.micros();

        local time3 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            local testClosure = function() { local captureSomething = testData; return captureSomething; }.bindenv(this);
        }
        local time4 = hardware.micros();

        local controlTime1 = hardware.micros();
        for( local i = 0; i < 100000; ++i ) {}
        local controlTime2 = hardware.micros();
        local controlTime = controlTime2 - controlTime1;

        return _printResults( "Regexp vs String find Comparison (x100,000)",
        [
            [ "Single closure", time2 - time1 ],
            [ "Multiple closures", time4 - time3 - controlTime ]
        ]);
    }

/*
    /// Tests to see if it's faster to:
    /// A. Lookup an interface as a string from shared a global class.
    /// B. Lookup an interface from a single global table (object).
    function stringInterfaceVsObjectInterface()
    {
        local myClass   = 
        class Object
        {
            static OBJECT_INTERFACES = {};

            function addInterface( name, functionList )
            {
                OBJECT_INTERFACES[name] <- functionList;
            }

            function implements( interfaceName )
            {
                if( !(interfaceName in OBJECT_INTERFACES) ) { return false; }

                local interface = OBJECT_INTERFACES[interfaceName];

                foreach( element in interface )
                {
                    try { this[element]; } catch( error ) { return false; }
                }

                return true;
            }

            function exists( objectName )
            {
                return objectName in this;
            }
        }
        local myClass2  = class MyClass2 { function someOtherFunction() {} };

        local time1 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            try { myClass[element]; } catch( error ) {}
        }
        local time2 = hardware.micros();

        local time3 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            try { myClass2[element]; } catch( error ) {}
        }
        local time4 = hardware.micros();

        local time5 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            if( element in MyClass ) { }
        }
        local time6 = hardware.micros();

        local time7 = hardware.micros();
        for( local i = 0; i < 100000; ++i )
        {
            if( element in MyClass2 ) { }
        }
        local time8 = hardware.micros();

        return _printResults( "Try vs In (x100,000)",
        [
            [ "Using Try when key exists", time2 - time1 ],
            [ "Using Try when key doesn't exist", time4 - time3 ],
            [ "Using In when key exists", time6 - time5 ],
            [ "Using In when key doesn't exist", time8 - time7 ]
        ]);
    }
*/
    function _printResults( testName, results )
    {
        results.sort( @( first, second ) first[1] <=> second[1] );

        local maxTestNameLength = results.reduce( @( previousValue, currentValue ) currentValue[0].len() > previousValue[0].len() ? currentValue : previousValue )[0].len();

        results = results.map( function( value )
        {
            local differenceInLength = maxTestNameLength - value[0].len();
            local newName = "";
            for( local i = 0; i < differenceInLength; ++i ) { newName += " "; }
            return [ newName + value[0], value[1].tofloat() ];
        });

        local output = testName + "\n";
        for( local i = 0; i < testName.len(); ++i ) { output += "-"; }
        output += "\n";

        foreach( result in results )
        {
            output += result[0] + ": " + format( "%7u", result[1] ) + "us / " + format( "%4u", result[1] / 1000 ) + "ms (" + format( "%.2f", result[1]/results[0][1]) + ")\n";
        }

        return output + "\n";
    }
}

performanceTests <- PerformanceTests();

imp.wakeup( 5, @() performanceTests.run() );

server.log( "Running Tests..." );