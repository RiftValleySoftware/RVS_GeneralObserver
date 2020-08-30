![Icon](icon.png)

# RVS_GeneralObserver

## DESCRIPTION

This is a general-purpose set of protocols that are designed to provide a simple infrastructure for a basic Observer implementation.

### Does Not Handle Messaging

This does not deal with messaging or managing communications between observers and observables. It simply gives them the infrastructure to track each other.

There are a few callbacks, explicitly related to aggregate management, but, otherwise, it's simply a tool to provide a reliable relationship graph management.

It is up to implementations to handle what to do with this information.

### Protocol-Based

This is based on protocols, as opposed to classes or structs. A couple of the protocols require that they be implemented as classes. There is heavy reliance of protocol default implementations to deliver the infrastructure.

## WHAT PROBLEM DOES THIS SOLVE?

At its heart, any observer implementation is really just a relationship graph. Observers _subscribe_ to Observables. Observables use the subscription as a one-way broadcast medium.

Managing the subscriptions and relationships is absolutely fundamental to the pattern. If we can't trust our subscription list, then everything built upon it is at risk.

### Different From Delegate

Apple uses the [Delegate](https://developer.apple.com/library/archive/documentation/General/Conceptual/CocoaEncyclopedia/DelegatesandDataSources/DelegatesandDataSources.html) pattern in a lot of their Cocoa infrastucture. This is an excellent and simple pattern that has the following features:

- Delegates are a "one-to-one" relationship. A class that has a delegate has only one delegate.
- Delegates are often "two-way" relationships. Delegates can send information back to the objects to which they are subscribed. In fact, [the Data Source pattern](https://developer.apple.com/library/archive/documentation/General/Conceptual/CocoaEncyclopedia/DelegatesandDataSources/DelegatesandDataSources.html#//apple_ref/doc/uid/TP40010810-CH11-SW6) codifies this explicitly.
- Delegates require that all involved entities be classes. In fact, delegates need to derive from [NSObject](https://developer.apple.com/documentation/objectivec/nsobject).

Observers (at least, they way I do them) have a different aspect:

- They are usually a "one-to-many" relationship. Observers _subscribe_ to observables, who are responsible for managing a list of subscribers.
- They are a "one-way" relationship. Observables can only send messages to subscribers. They cannot receive anything. If an observable wants to get messages from a subscriber, then the subscriber needs to become an observable, and the old observable needs to subscribe to them.
- It isn't a requirement for observers and observables to be classes, to satisfy the pattern, but I do require that a couple of the protocols be class-based protocols, in order to implement some of the defaults.

### Benefits

Managing the subscription lists and relationships is a very fundamental part of Observer, and something that needs to be rock-solid. That was why this tool was developed.
