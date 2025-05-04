# Monkey2/Wonkey Translation Guidelines for Runtime Components

*Implementation: iDkP from GaragePixel*  
*Date: 2025-05-04, Aida 4*

---

## Purpose

This document provides comprehensive guidelines for translating runtime components from Monkey2/Wonkey into Monkey2/Aida 4-compatible syntax. Adhering to these rules ensures consistency with the project's conventions while maintaining compatibility with Monkey2/Aida's advanced runtime features.

---

## Functionality

### General Conventions
- **File Header**: Include implementation credit, date, and Monkey2/Aida version in all files.
- **Commentary**: Begin each section with a clear explanation of its purpose and functionality. Use inline comments sparingly but effectively.

### Syntax Rules
- **Indentation**: Use tab-only indentation (spaces are strictly forbidden).
- **Block Termination**:
  - For loops terminate with `End`.
  - While loops terminate with `Wend`.
  - If/Else blocks terminate with `End` (one word).
  - Try/Catch blocks terminate with `End`. Avoid `End Try`.
  - Classes and methods must terminate with `End`.
- **Ternary Operators**: Use `?` and `Else` syntax (e.g., `Local value:Int = condition ? trueValue Else falseValue`).
- **Array Declarations**:
  - Use `New` keyword for array initialization.
  - Avoid slice syntax (e.g., `array[1..]`); manually copy elements to a new array.
- **Visibility Modifiers**:
  - Use `Public`, `Private`, and `Protected` explicitly.
  - Do not precede field declarations with `Private`; group private fields separately.
- **Reserved Words**: Avoid using reserved words (e.g., `end`, `namespace`, `throw`) as identifiers.

### Code Patterns
- **Class Pattern**:
    ```monkey2
    Class [ClassName] [Extends BaseClass] [Implements Interface1, Interface2]

        Public

        ' Constructor
        Method New(parameters)
            [initialization]
        End

        ' Method
        Method [name]:[ReturnType](parameters)
            [implementation]
        End

        Private

        Field _privateField:[Type]

    End
    ```
- **Property Pattern**:
    ```monkey2
    Property [Name]:[Type]()
        Return _backingField
    End

    Property [Name]:[Type]()
        Return _backingField
    Setter(value:[Type])
        _backingField = value
    End
    ```
- **Lazy Initialization Pattern**:
    ```monkey2
    Field _backingField:[Type]

    Property [Name]:[Type]()
        If _backingField = Null Then
            _backingField = [Initialization]
        End
        Return _backingField
    End
    ```
- **Error Handling**:
    ```monkey2
    Try
        [Implementation]
    Catch ex:[Type]
        [ErrorHandling]
    End
    ```

---

## Notes

### Implementation Choices
1. **Explicit Syntax**: Avoid implicit behaviors, such as auto-termination of blocks.
2. **Memory Management**: Replace slice syntax with explicit array copying to maintain performance and predictability.
3. **Ternary Operators**: Use `Else` instead of `:` to align with Monkey2/Aida's conditional expression parsing.

### Integration with Monkey2/Aida 4
- Monkey2/Aida 4's runtime analysis favors clear block structures and explicit termination.
- Avoid non-standard syntax (e.g., `end` as a variable name or `throw` for exceptions).
- Ensure all method parameters and local variables use type declarations.

---

## Technical Advantages

1. **Consistency**: Adhering to these guidelines ensures uniformity across all runtime components.
2. **Compatibility**: Aligns with Monkey2/Aida 4's syntax requirements for seamless integration.
3. **Performance**: Explicit array management prevents unnecessary memory allocations.
4. **Debugging**: Clear block termination simplifies stack trace analysis during runtime errors.
5. **Code Readability**: Terse but descriptive patterns improve maintainability.

---

*For further inquiries, refer to the [RULES_TO_CONTRIB.md](https://github.com/GaragePixel/stdlib-for-mx2/blob/main/RULES_TO_CONTRIB.md).*
