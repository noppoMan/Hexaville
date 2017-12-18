//The MIT License (MIT)
//
//Copyright (c) 2015 Matt
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

import Foundation

// MARK: Hashids options
public struct HashidsOptions {
    
    static let VERSION = "1.1.0"
    
    static var MIN_ALPHABET_LENGTH: Int = 16
    
    static var SEP_DIV: Double = 3.5
    
    static var GUARD_DIV: Double = 12
    
    static var ALPHABET: String = "abcdefghijklmnopqrstuvwxyz"
    
    static var SEPARATORS: String = "cfhistuCFHISTU"
    
}


// MARK: Hashids protocol
public protocol HashidsGenerator {
    associatedtype Char
    
    func encode(_ value: Int64...) -> String?
    
    func encode(_ values: [Int64]) -> String?
    
    func encode(_ value: Int...) -> String?
    
    func encode(_ values: [Int]) -> String?
    
    func decode(_ value: String!) -> [Int]
    
    func decode(_ value: [Char]) -> [Int]
    
    func decode64(_ value: String) -> [Int64]
    
    func decode64(_ value: [Char]) -> [Int64]
    
}


// MARK: Hashids class
public typealias Hashids = Hashids_<UInt32>


// MARK: Hashids generic class
open class Hashids_<T>: HashidsGenerator where T:UnsignedInteger {
    public typealias Char = T
    
    fileprivate var minHashLength: UInt
    
    fileprivate var alphabet: [Char]
    
    fileprivate var seps: [Char]
    
    fileprivate var salt: [Char]
    
    fileprivate var guards: [Char]
    
    public init(salt: String!, minHashLength: UInt = 0, alphabet: String? = nil) {
        var _alphabet = (alphabet != nil) ? alphabet! : HashidsOptions.ALPHABET
        var _seps = HashidsOptions.SEPARATORS
        
        self.minHashLength = minHashLength
        self.guards = [Char]()
        self.salt = salt.unicodeScalars.map() {
            numericCast($0.value)
        }
        self.seps = _seps.unicodeScalars.map() {
            numericCast($0.value)
        }
        self.alphabet = unique(_alphabet.unicodeScalars.map() {
            numericCast($0.value)
        })
        
        self.seps = intersection(self.alphabet, self.seps)
        self.alphabet = difference(self.alphabet, self.seps)
        shuffle(&self.seps, self.salt)
        
        
        let sepsLength = self.seps.count
        let alphabetLength = self.alphabet.count
        
        if (0 == sepsLength) || (Double(alphabetLength) / Double(sepsLength) > HashidsOptions.SEP_DIV) {
            
            var newSepsLength = Int(ceil(Double(alphabetLength) / HashidsOptions.SEP_DIV))
            
            if 1 == newSepsLength {
                newSepsLength += 1
            }
            
            if newSepsLength > sepsLength {
                let diff = self.alphabet.startIndex.advanced(by: newSepsLength - sepsLength)
                let range = 0 ..< diff
                self.seps += self.alphabet[range]
                self.alphabet.removeSubrange(range)
            } else {
                let pos = self.seps.startIndex.advanced(by: newSepsLength)
                self.seps.removeSubrange(pos + 1 ..< self.seps.count)
            }
        }
        
        shuffle(&self.alphabet, self.salt)
        
        let guard_i = Int(ceil(Double(alphabetLength) / HashidsOptions.GUARD_DIV))
        if alphabetLength < 3 {
            let seps_guard = self.seps.startIndex.advanced(by: guard_i)
            let range = 0 ..< seps_guard
            self.guards += self.seps[range]
            self.seps.removeSubrange(range)
        } else {
            let alphabet_guard = self.alphabet.startIndex.advanced(by: guard_i)
            let range = 0 ..< alphabet_guard
            self.guards += self.alphabet[range]
            self.alphabet.removeSubrange(range)
        }
    }
    
    // MARK: public api
    
    open func encode(_ value: Int64...) -> String? {
        return encode(value)
    }
    
    open func encode(_ values: [Int64]) -> String? {
        return encode(values.map { Int($0) })
    }
    
    open func encode(_ value: Int...) -> String? {
        return encode(value)
    }
    
    open func encode(_ values: [Int]) -> String? {
        let ret = _encode(values)
        return ret.reduce(String(), { ( so, i) in
            var so = so
            let scalar: UInt32 = numericCast(i)
            if let uniscalar = UnicodeScalar(scalar) {
                so.append(String(describing: uniscalar))
            }
            return so
        })
    }
    
    open func decode(_ value: String!) -> [Int] {
        let trimmed = value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let hash: [Char] = trimmed.unicodeScalars.map() {
            numericCast($0.value)
        }
        return self.decode(hash)
    }
    
    open func decode(_ value: [Char]) -> [Int] {
        return self._decode(value)
    }
    
    open func decode64(_ value: String) -> [Int64] {
        return self.decode(value).map { Int64($0) }
    }
    
    open func decode64(_ value: [Char]) -> [Int64] {
        return self.decode(value).map { Int64($0) }
    }
    
    // MARK: private funcitons
    fileprivate func _encode(_ numbers: [Int]) -> [Char] {
        var alphabet = self.alphabet
        var numbers_hash_int = 0
        
        for (index, value) in numbers.enumerated() {
            numbers_hash_int += (value % (index + 100))
        }
        
        let lottery = alphabet[numbers_hash_int % alphabet.count]
        var hash = [lottery]
        
        var lsalt = [Char]()
        let (lsaltARange, lsaltRange) = _saltify(&lsalt, lottery, alphabet)
        
        for (index, value) in numbers.enumerated() {
            shuffle(&alphabet, lsalt, lsaltRange)
            let lastIndex = hash.endIndex
            _hash(&hash, value, alphabet)
            
            if index + 1 < numbers.count {
                let number = value % (numericCast(hash[lastIndex]) + index)
                let seps_index = number % self.seps.count
                hash.append(self.seps[seps_index])
            }
            
            lsalt.replaceSubrange(lsaltARange, with: alphabet)
        }
        
        let minLength: Int = numericCast(self.minHashLength)
        
        if hash.count < minLength {
            let guard_index = (numbers_hash_int + numericCast(hash[0])) % self.guards.count
            let guard_t = self.guards[guard_index]
            hash.insert(guard_t, at: 0)
            
            if hash.count < minLength {
                let guard_index = (numbers_hash_int + numericCast(hash[2])) % self.guards.count
                let guard_t = self.guards[guard_index]
                hash.append(guard_t)
            }
        }
        
        let half_length = alphabet.count >> 1
        while hash.count < minLength {
            shuffle(&alphabet, alphabet)
            let lrange = Range<Int>(0 ..< half_length)
            let rrange = Range<Int>(half_length ..< (alphabet.count))
            let alphabet_right = alphabet[rrange]
            let alphabet_left = alphabet[lrange]
            hash = Array<Char>(alphabet_right) + hash + Array<Char>(alphabet_left)
            
            let excess = hash.count - minLength
            if excess > 0 {
                let start = excess >> 1
                hash = [Char](hash[start ..< (start + minLength)])
            }
        }
        
        return hash
    }
    
    fileprivate func _decode(_ hash: [Char]) -> [Int] {
        var ret = [Int]()
        
        var alphabet = self.alphabet
        
        var hashes = hash.split(maxSplits: hash.count, omittingEmptySubsequences: false) {
            contains(self.guards, $0)
        }
        let hashesCount = hashes.count, i = ((hashesCount == 2) || (hashesCount == 3)) ? 1 : 0
        let hash = hashes[i]
        let hashStartIndex = hash.startIndex
        
        if hash.count > 0 {
            let lottery = hash[hashStartIndex]
            let valuesHashes = hash[(hashStartIndex + 1) ..< (hashStartIndex + hash.count)]
            
            let valueHashes = valuesHashes.split(maxSplits: valuesHashes.count, omittingEmptySubsequences: false) {
                contains(self.seps, $0)
            }
            var lsalt = [Char]()
            let (lsaltARange, lsaltRange) = _saltify(&lsalt, lottery, alphabet)
            
            for subHash in valueHashes {
                shuffle(&alphabet, lsalt, lsaltRange)
                ret.append(self._unhash(subHash, alphabet))
                lsalt.replaceSubrange(lsaltARange, with: alphabet)
            }
        }
        
        return ret
    }
    
    fileprivate func _hash(_ hash: inout [Char], _ number: Int, _ alphabet: [Char]) {
        var number = number
        let length = alphabet.count, index = hash.count
        repeat {
            hash.insert(alphabet[number % length], at: index)
            number = number / length
        } while (number != 0)
    }
    
    fileprivate func _unhash<U:Collection>(_ hash: U, _ alphabet: [Char]) -> Int where U.Index == Int, U.Iterator.Element == Char {
        var value: Double = 0
        
        var hashLength: Int = numericCast(hash.count)
        if hashLength > 0 {
            let alphabetLength = alphabet.count
            value = hash.reduce(0) {
                value, token in
                var tokenValue = 0.0
                if let token_index = alphabet.index(of: token as Char) {
                    hashLength = hashLength - 1
                    let mul = pow(Double(alphabetLength), Double(hashLength))
                    tokenValue = Double(token_index) * mul
                }
                return value + tokenValue
            }
        }
        
        return Int(trunc(value))
    }
    
    fileprivate func _saltify(_ salt: inout [Char], _ lottery: Char, _ alphabet: [Char]) -> (Range<Int>, Range<Int>) {
        salt.append(lottery)
        salt = salt + self.salt
        salt = salt + alphabet
        let lsaltARange = (self.salt.count + 1) ..< salt.count
        let lsaltRange = 0 ..< alphabet.count
        return (Range<Int>(lsaltARange), Range<Int>(lsaltRange))
    }
    
}

// MARK: Internal functions
internal func contains<T:Collection>(_ a: T, _ e: T.Iterator.Element) -> Bool where T.Iterator.Element:Equatable {
    return (a.index(of: e) != nil)
}

internal func transform<T:Collection>(_ a: T, _ b: T, _ cmpr: (inout Array<T.Iterator.Element>, T, T, T.Iterator.Element) -> Void) -> [T.Iterator.Element] where T.Iterator.Element:Equatable {
    typealias U = T.Iterator.Element
    var c = [U]()
    for i in a {
        cmpr(&c, a, b, i)
    }
    return c
}

internal func unique<T:Collection>(_ a: T) -> [T.Iterator.Element] where T.Iterator.Element:Equatable {
    return transform(a, a) {
        ( c, a, b, e) in
        if !contains(c, e) {
            c.append(e)
        }
    }
}

internal func intersection<T:Collection>(_ a: T, _ b: T) -> [T.Iterator.Element] where T.Iterator.Element:Equatable {
    return transform(a, b) {
        ( c, a, b, e) in
        if contains(b, e) {
            c.append(e)
        }
    }
}

internal func difference<T:Collection>(_ a: T, _ b: T) -> [T.Iterator.Element] where T.Iterator.Element:Equatable {
    return transform(a, b) {
        ( c, a, b, e) in
        if !contains(b, e) {
            c.append(e)
        }
    }
}
internal func shuffle<T:MutableCollection, U:Collection>(_ source: inout T, _ salt: U) where T.Index == Int, T.Iterator.Element:UnsignedInteger, T.Iterator.Element == U.Iterator.Element, T.Index == U.Index {
    let saltCount: Int = numericCast(salt.count)
    shuffle(&source, salt, 0 ..< saltCount)
}

internal func shuffle<T:MutableCollection, U:Collection>(_ source: inout T, _ salt: U, _ saltRange: Range<Int>) where T.Index == Int, T.Iterator.Element:UnsignedInteger, T.Iterator.Element == U.Iterator.Element, T.Index == U.Index {
    let sidx0 = saltRange.lowerBound, scnt = (saltRange.upperBound - saltRange.lowerBound)
    var sidx: Int = numericCast(source.count) - 1, v = 0, _p = 0
    while sidx > 0 {
        v = v % scnt
        let _i: Int = numericCast(salt[sidx0 + v])
        _p += _i
        let _j: Int = (_i + v + _p) % sidx
        let tmp = source[sidx]
        source[sidx] = source[_j]
        source[_j] = tmp
        v += 1
        sidx = sidx - 1
    }
}
