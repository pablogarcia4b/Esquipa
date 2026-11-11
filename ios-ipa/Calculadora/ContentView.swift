import SwiftUI

enum CalcButton: String {
    case zero = "0", one = "1", two = "2", three = "3", four = "4"
    case five = "5", six = "6", seven = "7", eight = "8", nine = "9"
    case decimal = ","
    case equals = "="
    case plus = "+"
    case minus = "−"
    case multiply = "×"
    case divide = "÷"
    case clear = "AC"
    case sign = "±"
    case percent = "%"

    var backgroundColor: Color {
        switch self {
        case .clear, .sign, .percent:
            return Color(red: 0.65, green: 0.65, blue: 0.65)
        case .divide, .multiply, .minus, .plus, .equals:
            return Color(red: 1.0, green: 0.62, blue: 0.04)
        default:
            return Color(red: 0.2, green: 0.2, blue: 0.2)
        }
    }

    var foregroundColor: Color {
        switch self {
        case .clear, .sign, .percent:
            return .black
        default:
            return .white
        }
    }
}

struct ContentView: View {
    @State private var display = "0"
    @State private var history = ""
    @State private var previousValue: Double? = nil
    @State private var currentOperator: CalcButton? = nil
    @State private var waitingForSecondOperand = false

    let buttons: [[CalcButton]] = [
        [.clear, .sign, .percent, .divide],
        [.seven, .eight, .nine, .multiply],
        [.four, .five, .six, .minus],
        [.one, .two, .three, .plus],
        [.zero, .decimal, .equals]
    ]

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 14
            let totalSpacing = spacing * 5
            let btnSize = (geo.size.width - totalSpacing) / 4

            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: spacing) {
                    Spacer()

                    // Pantalla de resultados (desliza para borrar el último dígito)
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(history)
                            .font(.system(size: 26, weight: .regular))
                            .foregroundColor(.gray)
                            .lineLimit(1)

                        Text(formatDisplay(display))
                            .font(.system(size: 84, weight: .light))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 30)
                            .onEnded { _ in deleteLastDigit() }
                    )

                    // Botonera
                    ForEach(buttons, id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(row, id: \.self) { button in
                                Button(action: { buttonTapped(button) }) {
                                    Text(buttonTitle(button))
                                        .font(.system(size: 34, weight: .medium))
                                        .frame(
                                            width: button == .zero ? btnSize * 2 + spacing : btnSize,
                                            height: btnSize
                                        )
                                        .frame(alignment: button == .zero ? .leading : .center)
                                        .background(isOperatorActive(button) ? Color.white : button.backgroundColor)
                                        .foregroundColor(isOperatorActive(button) ? Color(red: 1.0, green: 0.62, blue: 0.04) : button.foregroundColor)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }

    private func buttonTitle(_ button: CalcButton) -> String {
        if button == .clear {
            return (display != "0" || waitingForSecondOperand) ? "C" : "AC"
        }
        if button == .zero {
            return "      0"
        }
        return button.rawValue
    }

    private func isOperatorActive(_ button: CalcButton) -> Bool {
        return waitingForSecondOperand && currentOperator == button
    }

    private func formatDisplay(_ raw: String) -> String {
        if raw == "Error" { return "Error" }
        return raw.replacingOccurrences(of: ".", with: ",")
    }

    private func deleteLastDigit() {
        guard !waitingForSecondOperand && display != "Error" else { return }
        if display.count <= 1 || (display.count == 2 && display.hasPrefix("-")) {
            display = "0"
        } else {
            display.removeLast()
        }
    }

    private func buttonTapped(_ button: CalcButton) {
        switch button {
        case .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine:
            inputDigit(button.rawValue)
        case .decimal:
            inputDecimal()
        case .clear:
            clearPressed()
        case .sign:
            toggleSign()
        case .percent:
            applyPercent()
        case .divide, .multiply, .minus, .plus:
            handleOperator(button)
        case .equals:
            calculateEquals()
        }
    }

    private func inputDigit(_ digit: String) {
        if display == "Error" { resetAll() }
        if waitingForSecondOperand {
            display = digit
            waitingForSecondOperand = false
        } else {
            let digitsOnly = display.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: ".", with: "")
            guard digitsOnly.count < 9 else { return }
            display = display == "0" ? digit : display + digit
        }
    }

    private func inputDecimal() {
        if display == "Error" { resetAll() }
        if waitingForSecondOperand {
            display = "0."
            waitingForSecondOperand = false
            return
        }
        if !display.contains(".") {
            display += "."
        }
    }

    private func clearPressed() {
        if display != "0" {
            display = "0"
        } else {
            resetAll()
        }
    }

    private func resetAll() {
        display = "0"
        history = ""
        previousValue = nil
        currentOperator = nil
        waitingForSecondOperand = false
    }

    private func toggleSign() {
        guard display != "0" && display != "Error" else { return }
        if display.hasPrefix("-") {
            display.removeFirst()
        } else {
            display = "-" + display
        }
    }

    private func applyPercent() {
        guard let val = Double(display) else { return }
        if let prev = previousValue, (currentOperator == .plus || currentOperator == .minus) {
            display = formatNumberResult(prev * (val / 100.0))
        } else {
            display = formatNumberResult(val / 100.0)
        }
    }

    private func handleOperator(_ op: CalcButton) {
        guard let inputVal = Double(display) else { return }
        if let prev = previousValue, let activeOp = currentOperator, !waitingForSecondOperand {
            if let result = performCalculation(prev, inputVal, activeOp) {
                display = formatNumberResult(result)
                previousValue = result
            } else {
                display = "Error"
                previousValue = nil
            }
        } else {
            previousValue = inputVal
        }
        currentOperator = op
        waitingForSecondOperand = true
        if let prev = previousValue {
            history = "\(formatNumberResult(prev).replacingOccurrences(of: ".", with: ",")) \(op.rawValue)"
        }
    }

    private func calculateEquals() {
        guard let prev = previousValue,
              let op = currentOperator,
              let inputVal = Double(display) else { return }

        let prevText = formatNumberResult(prev).replacingOccurrences(of: ".", with: ",")
        let currText = formatNumberResult(inputVal).replacingOccurrences(of: ".", with: ",")
        history = "\(prevText) \(op.rawValue) \(currText) ="

        if let result = performCalculation(prev, inputVal, op) {
            display = formatNumberResult(result)
        } else {
            display = "Error"
        }
        previousValue = nil
        currentOperator = nil
        waitingForSecondOperand = true
    }

    private func performCalculation(_ a: Double, _ b: Double, _ op: CalcButton) -> Double? {
        switch op {
        case .plus: return a + b
        case .minus: return a - b
        case .multiply: return a * b
        case .divide: return b == 0 ? nil : a / b
        default: return b
        }
    }

    private func formatNumberResult(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 && abs(value) < 1e12 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.8g", value)
    }
}
