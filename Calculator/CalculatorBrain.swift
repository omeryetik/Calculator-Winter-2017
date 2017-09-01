//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Ömer Yetik on 14/08/2017.
//  Copyright © 2017 Ömer Yetik. All rights reserved.
//

import Foundation

struct CalculatorBrain {
    
    // MARK: Public Variables
    //
    
    //  A1RT5
    @available(iOS, deprecated, message: "Will be dropped. Use evaluate(:) function instead")
    var resultIsPending: Bool {
        get {
            return evaluate(using: valueForVariable).isPending
        }
    }  //
    
    @available(iOS, deprecated, message: "Will be dropped. Use evaluate(:) function instead")
    var result: Double? {
        get {
            return evaluate(using: valueForVariable).result
        }
    }
    
    //  A1RT6
    @available(iOS, deprecated, message: "Will be dropped. Use evaluate(:) function instead")
    var description: String? {
        get {
            return evaluate(using: valueForVariable).description
        }
    }  //
    
    
    // MARK: Internal (private) Variables
    //
    
    //  A2RT3-4 : Create an internal array with elements of type "enum ProgramItem"
    //            This array is going to hold a sequence of operations, operands and
    //            variables in the form of a CalculatorBrain program
    private enum ProgramItem {
        case aDouble(Double)
        case anOperation(String)
        case aVariable(String)
    }
    
    private var internalProgram = [ProgramItem]()
    
    //  Initialize the variables Dictionary as an empty Dictionary of [String:Double]
    private var valueForVariable = Dictionary<String, Double>()
    
    //
    
    
    //  Int values for operation types are added for precedence detection in
    //  generating the description String (A1RT6)
    private enum Operation {
        case constant(Double)
        //  A1ECT3
        case nullaryOperation(()-> Double, (Double) -> String)
        //
        case unaryOperation((Double) -> Double, (String) -> String)
        case binaryOperation((Double, Double) -> Double, (String, String) -> String, Int)
        case equals
    }
    
    
    private var operations: Dictionary<String,Operation> = [
        "π"     : Operation.constant(Double.pi),
        "e"     : Operation.constant(M_E),
        "√"     : Operation.unaryOperation(sqrt, { "√" + "(" + $0 + ")" }),
        //  A1RT2 : New operations added
        "∛"     : Operation.unaryOperation({ pow($0, 1/3) }, { "∛" + "(" + $0 + ")" }),
        "x⁻¹"   : Operation.unaryOperation({ pow($0, -1) }, { "(" + $0 + ")⁻¹" }),
        "x²"    : Operation.unaryOperation({ pow($0, 2) }, { "(" + $0 + ")²" }),
        "x³"    : Operation.unaryOperation({ pow($0, 3) }, { "(" + $0 + ")³" }),
        "cos"   : Operation.unaryOperation(cos, { "cos(" + $0 + ")" }),
        "sin"   : Operation.unaryOperation(sin, { "sin(" + $0 + ")" }),
        "tan"   : Operation.unaryOperation(tan, { "tan(" + $0 + ")⁻¹" }),
        "log₁₀" : Operation.unaryOperation(log10, { "log₁₀(" + $0 + ")" }),
        "eˣ"    : Operation.unaryOperation({ pow(M_E, $0) }, { "e^(" + $0 + ")" }),
        "±"     : Operation.unaryOperation({ -$0 }, { "±(" + $0 + ") " }),
        "×"     : Operation.binaryOperation({ $0 * $1 }, { $0 + " × " + $1 }, 1),
        "+"     : Operation.binaryOperation({ $0 + $1 }, { $0 + " + " + $1 }, 0),
        "÷"     : Operation.binaryOperation({ $0 / $1 }, { $0 + " ÷ " + $1 }, 1),
        "−"     : Operation.binaryOperation({ $0 - $1 }, { $0 + " − " + $1 }, 0),
        "xʸ"    : Operation.binaryOperation(pow, { "(" + $0 + "^" + $1 + ")" }, 0),
        //
        "rand"  : Operation.nullaryOperation({ Double(arc4random())/Double(UInt32.max) }, { numberFormatter.string(from: NSNumber(value: $0))! }),
        "="     : Operation.equals
    ]
    
    
    private struct PendingBinaryOperation {
        let function: (Double, Double) -> Double
        let firstOperand: Double
        
        func perform(with secondOperand: Double) -> Double {
            return function(firstOperand, secondOperand)
        }
        
        let descriptionFunction: (String, String) -> String
        let firstOperandDescription: String
        
        func describe(with secondOperandDescription: String) -> String {
            return descriptionFunction(firstOperandDescription, secondOperandDescription)
        }
    }
    
    // MARK: Public Functions
    //
    mutating func setOperand(_ operand: Double) {
        //  A2RT3-4 : Append operand to internalProgram array
        internalProgram.append(ProgramItem.aDouble(operand))
        //
    }
    
    mutating func performOperation(_ symbol: String) {
        //  A2RT3-4 : Append operand to internalProgram array
        internalProgram.append(ProgramItem.anOperation(symbol))
        //
    }
    
    //  A2RT3-4 : Variable support - Begin
    
    mutating func setOperand(variable named: String) {
        //  A2RT3-4 : Append operand to internalProgram array
        internalProgram.append(ProgramItem.aVariable(named))
        //
    }
    
    func evaluate(using variables: Dictionary<String,Double>? = nil) -> (result: Double?, isPending: Bool, description: String) {
        
        // MARK: CalculatorBrain variables as local variables in evaluate(:) function
        //
        
        //  Define accumulator as a Tuple of a Double? value and a String? description
        var accumulator: (value: Double?, description: String?)
        
        var lastOperationPrecedence = Int.max
        
        var pendingBinaryOperation: PendingBinaryOperation?
        
        
        // MARK: Nested functions in evaluate(:)
        //  Make performOperation(_ symbol: String) a nested function enclosed in
        //  evaluate function
        func performOperation(_ symbol: String) {
            if let operation = operations[symbol] {
                switch operation {
                case .constant(let value):
                    accumulator.value = value
                    accumulator.description = symbol
                case .nullaryOperation(let function, let descriptionFunction):
                    accumulator.value = function()
                    accumulator.description = descriptionFunction(accumulator.value!)
                //  A1ECT3
                case .unaryOperation(let function, let descriptionFunction):
                    if accumulator.value != nil {
                        accumulator.value = function(accumulator.value!)
                        accumulator.description = descriptionFunction(accumulator.description!)
                    }
                //
                case .binaryOperation(let function, let descriptionFunction, let currentOperationPrecedence):
                    //  call performPendingBinaryOperation() for chained binary operations to work
                    performPendingBinaryOperation()
                    if lastOperationPrecedence  < currentOperationPrecedence {
                        accumulator.description = "(" + accumulator.description! + ")"
                    }
                    lastOperationPrecedence = currentOperationPrecedence
                    if accumulator.value != nil {
                        pendingBinaryOperation = PendingBinaryOperation(function: function, firstOperand: accumulator.value!, descriptionFunction: descriptionFunction, firstOperandDescription: accumulator.description!)
                        accumulator.value = nil
                        accumulator.description = nil
                    }
                case .equals:
                    performPendingBinaryOperation()
                }
            }
        }

        //  Make performPendingBinaryOperationa nested function enclosed in
        //  evaluate function
        func performPendingBinaryOperation() {
            if pendingBinaryOperation != nil && accumulator.value != nil {
                accumulator.value = pendingBinaryOperation!.perform(with: accumulator.value!)
                accumulator.description = pendingBinaryOperation!.describe(with: accumulator.description!)
                pendingBinaryOperation = nil
            }
        }
        
        // MARK: Main functionality of evaluate(:) function
        for programItem in internalProgram {
            switch programItem {
            case .aDouble(let number):
                accumulator.value = number
                accumulator.description = numberFormatter.string(from: NSNumber(value: number))
            case .anOperation(let operation):
                performOperation(operation)
            case .aVariable(let variable):
                accumulator.value = valueForVariable[variable]
            }
        }
        
        
        // MARK: Return values for evaluate(:) function
        
        var isPending: Bool {
            get {
                return pendingBinaryOperation != nil
            }
        }  //
        
        var result: Double? {
            get {
                return accumulator.value
            }
        }
        
        //  A1RT6
        var description: String {
            get {
                if pendingBinaryOperation == nil {
                    return accumulator.description!
                } else {
                    return pendingBinaryOperation!.describe(with: accumulator.description ?? "")
                }
            }
        }
        //
        
        return (result, isPending, description)
    }   //  A2RT3-4 : Variable support - End

    
    //  A1RT7
    mutating func reset() {
        self = CalculatorBrain()
    }  //
    
}

