//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Ömer Yetik on 14/08/2017.
//  Copyright © 2017 Ömer Yetik. All rights reserved.
//

import Foundation

struct CalculatorBrain {
    
    //  Define accumulator as a Tuple of a Double? value and a String? description
    private var accumulator: (value: Double?, description: String?)
    
    private var lastOperationPrecedence = Int.max
    
    //  Int values for operation types are added for precedence detection in
    //  generating the description String (A1RT6)
    private enum Operation {
        case constant(Double)
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
        //  A1RT2
        "="     : Operation.equals
    ]
    
    mutating func performOperation(_ symbol: String) {
        if let operation = operations[symbol] {
            switch operation {
            case .constant(let value):
                accumulator.value = value
                accumulator.description = symbol
            case .unaryOperation(let function, let descriptionFunction):
                if accumulator.value != nil {
                    accumulator.value = function(accumulator.value!)
                    accumulator.description = descriptionFunction(accumulator.description!)
                }
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
    
    private mutating func performPendingBinaryOperation() {
        if pendingBinaryOperation != nil && accumulator.value != nil {
            accumulator.value = pendingBinaryOperation!.perform(with: accumulator.value!)
            accumulator.description = pendingBinaryOperation!.describe(with: accumulator.description!)
            pendingBinaryOperation = nil
        }
    }
    
    private var pendingBinaryOperation: PendingBinaryOperation?
    
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
    
    mutating func setOperand(_ operand: Double) {
        accumulator.value = operand
        accumulator.description = String(format:"%g", operand) //
    }
    
    //  A1RT5
    var resultIsPending: Bool {
        get {
            return pendingBinaryOperation != nil
        }
    }
    //  A1RT5
    
    var result: Double? {
        get {
            return accumulator.value
        }
    }
    
    //  A1RT6
    var description: String? {
        get {
            if pendingBinaryOperation == nil {
                return accumulator.description!
            } else {
                return pendingBinaryOperation!.describe(with: accumulator.description ?? "")
            }
        }
    }
    //  A1RT6
    
    //  A1RT7
    mutating func reset() {
        self = CalculatorBrain()
    }
    //  A1RT7
    
}
