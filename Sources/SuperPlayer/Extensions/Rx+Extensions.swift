//
//  Rx+Extensions.swift
//  Source
//
//  Created by Andrey Yoshua on 04/08/21.
//

//import Foundation
//import RxCocoa
//import RxSwift
//
//
//extension ObservableType where Element == Bool {
//    /// Boolean not operator
//    public func not() -> Observable<Bool> {
//        return map(!)
//    }
//}
//
//extension SharedSequenceConvertibleType {
//    public func mapToVoid() -> SharedSequence<SharingStrategy, Void> {
//        return map { _ in }
//    }
//}
//
//extension ObservableType {
//    public func catchErrorJustComplete() -> Observable<Element> {
//        return catchError { _ in
//            Observable.empty()
//        }
//    }
//
//    public func asDriverOnErrorJustComplete() -> Driver<Element> {
//        return asDriver { _ in
//            Driver.empty()
//        }
//    }
//
//    public func mapToVoid() -> Observable<Void> {
//        return map { _ in }
//    }
//}
