//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Ömer Yetik on 14/08/2017.
//  Copyright © 2017 Ömer Yetik. All rights reserved.
//

import Foundation

struct CalculatorBrain {
    
    private var accumulator: Double?
    
//    Int values for operation types are added for precedence detection in 
//    generating the description String (A1RT6)
    private enum Operation {
        case constant(Double)
        case unaryOperation((Double) -> Double)
        case binaryOperation((Double, Double) -> Double, Int)
        case equals
    }
    
    private var operations: Dictionary<String,Operation> = [
        "π"     : Operation.constant(Double.pi),
        "e"     : Operation.constant(M_E),
        "√"     : Operation.unaryOperation(sqrt),
//        A1RT2 : New operations added
        "∛"     : Operation.unaryOperation({ pow($0, 1/3) }),
        "x⁻¹"   : Operation.unaryOperation({ pow($0, -1) }),
        "x²"    : Operation.unaryOperation({ pow($0, 2) }),
        "x³"    : Operation.unaryOperation({ pow($0, 3) }),
        "cos"   : Operation.unaryOperation(cos),
        "sin"   : Operation.unaryOperation(sin),
        "tan"   : Operation.unaryOperation(tan),
        "log₁₀" : Operation.unaryOperation(log10),
        "eˣ"    : Operation.unaryOperation({ pow(M_E, $0) }),
        "±"     : Operation.unaryOperation({ -$0 }),
        "×"     : Operation.binaryOperation({ $0 * $1 }, 1),
        "+"     : Operation.binaryOperation({ $0 + $1 }, 0),
        "÷"     : Operation.binaryOperation({ $0 / $1 }, 1),
        "−"     : Operation.binaryOperation({ $0 - $1 }, 0),
        "xʸ"    : Operation.binaryOperation(pow, 0),
//        A1RT2
        "="     : Operation.equals
    ]
    
    mutating func performOperation(_ symbol: String) {
        if let operation = operations[symbol] {
            switch operation {
            case .constant(let value):
                accumulator = value
            case .unaryOperation(let function):
                if accumulator != nil {
                    accumulator = function(accumulator!)
                }
            case .binaryOperation(let function, _):
//                call performPendingBinaryOperation() for chained binary operations to work
                performPendingBinaryOperation()
                if accumulator != nil {
                    pendingBinaryOperation = PendingBinaryOperation(function: function, firstOperand: accumulator!)
                }
            case .equals:
                performPendingBinaryOperation()
            }
        }
    }
    
    private mutating func performPendingBinaryOperation() {
        if pendingBinaryOperation != nil && accumulator != nil {
            accumulator = pendingBinaryOperation!.perform(with: accumulator!)
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
    }
    
//    A1RT5
    private var resultIsPending: Bool {
        get {
            return pendingBinaryOperation != nil
        }
    }
//    A1RT5
    
    mutating func setOperand(_ operand: Double) {
        accumulator = operand
    }
    
    var result: Double? {
        get {
            return accumulator
        }
    }
    
}
