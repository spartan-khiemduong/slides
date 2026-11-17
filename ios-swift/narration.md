<!-- Teaching narration for the iOS Swift deck: one block per slide, in slide order, split by lines of "---".
     Written to be read aloud by macOS `say` (scripts/make-video.sh), so code is spelled out in words. -->

Welcome. This lesson teaches you the iOS Swift part of our three-part iOS session, so you can present it yourself later. We will walk through every slide. For each one, I will explain the idea, point at the real code from the MotivationFit app, and tell you what to say and what to emphasize. The goal is simple: by the end, you should understand the Swift language features our app is built with, and know why we use them.

---

First, where this talk sits. The iOS session has three parts. Part one is yours: iOS Swift. That means the language itself: types, protocols, errors, concurrency, and modules. Part two is Khoa: components and state management, which covers SwiftUI views and property wrappers like State, Observable and Environment. Part three is Kiet: the MVVM architecture, meaning how views, models, stores and repositories fit together. Your job is to lay the foundation. When you touch Observable or State, only say what they are as Swift features, and tell the audience Khoa will show how they work. The path for today is: setup, value types, protocols and generics, errors, then the big one, concurrency, and finally modules and tooling.

---

This slide gives the audience a feel for the codebase. There are 318 Swift files in the MotivationFit package. Look at the numbers. 287 structs, but only 67 classes, so value types win four to one. About 260 await keywords, so asynchronous code is everywhere. 170 types are marked Sendable. And here is the number to point at: zero uses of unchecked Sendable. That is the unsafe escape hatch for concurrency, and we never needed it. We also have 78 test files written with Swift Testing, and 114 previews. Tell the audience: keep these numbers in mind, every section today explains one of them.

---

Section one: the setup. Before we look at any language feature, we need to know the rules our code is compiled under, because those rules shape everything else.

---

These rules come from the AGENTS file in the iOS folder, hard rules four to six. One: Swift 6 language mode. That turns on complete strict concurrency checking, so possible data races become compile errors instead of runtime crashes. Two: warnings are errors. Nothing temporary survives a build. Three: the app target defaults to the main actor, which means UI code runs on the main thread unless we say otherwise. Four: unchecked Sendable and nonisolated unsafe are forbidden without a written proof. Five: the minimum is iOS 18, and anything newer must sit behind an availability check with a fallback. Six: we use the Observation framework only, no ObservableObject, and no print statements. The key message to deliver: these are not style preferences. The compiler enforces them. If it builds, a whole class of threading bugs is already gone.

---

Here is where those rules live: Package dot swift, the manifest for our Swift package. The tools version is 6.2, and the platform is iOS 18. The strict list applies to every module. It treats all warnings as errors, and it turns on three upcoming features. Look at the table below. Nonisolated non-sending by default means an async function runs on its caller's actor. It does not silently jump to a background thread anymore. If you really want to leave the actor, you write the concurrent attribute. Default isolation main actor is added only for UI modules. It means every type in that module is main actor isolated unless you say otherwise, so view code needs no annotations. Member import visibility means a file can only use another module's members if that file itself imports the module. So the import lines at the top of a file tell the truth. Together, Apple calls this approachable concurrency.

---

Now the entry point of the app, in MotivationFit dot swift. The whole app starts from a struct. Count the language features in these few lines. The at-main attribute marks where the program starts. The struct conforms to the App protocol. The at-State and the delegate adaptor are property wrappers. The body returns some Scene, which is an opaque type, and the closures after WindowGroup and onOpenURL are trailing closures. One small detail worth explaining: underscore model equals State, initial value. That is how you set a property wrapper's storage directly inside an initializer. When you present, use this slide to show that even fifteen lines of Swift use five or six language features, and that we will now go through them one by one.

---

Section two: value types. In Swift, structs and enums come first. Classes are the exception.

---

Here is a typical model: CatalogTag. It is a struct, its properties are let constants, and it conforms to Codable, Sendable, Hashable and Identifiable. Why a struct? First, value semantics. When you pass a struct around, you pass a copy, so nobody can change it behind your back. Second, let properties make it immutable, which makes it safe to share. Third, it is Sendable for free, because all of its fields are Sendable. Fourth, the compiler synthesizes the conformances. We never hand-write the encoding, the hashing, or the equality. So when do we use a class? Only when identity matters: one shared thing that changes over time, like a store, a player, or a view model. All 67 of our classes are marked final. Final means no subclassing, which lets the compiler use fast static dispatch. In practice, we never use inheritance.

---

Enums with associated values. Explore shows one mixed list that contains both sessions and courses. CatalogItem models that. It has two cases: session, which carries a SessionCard, and program, which carries a ProgramCard. Why is this better than a struct with an optional session and an optional program? Because with two optionals, both could be nil, or both could be set, and those states make no sense. With the enum, a value is exactly one of the two. Impossible states cannot even be built. Next, look at the id property. It switches over self, and the switch is exhaustive. If someone adds a third case later, every switch in the codebase fails to compile until it handles the new case. And since Swift 5.9, switch is an expression, so we do not even need the return keyword.

---

Raw value enums, plus defensive decoding. SessionType has a String raw value for every case, like TALK and GUIDED, matching the backend's JSON. Notice the extra case: unknown. Then look at the custom decoder initializer. It decodes the raw string, tries to build a SessionType from it, and if that fails, the double question mark, the nil coalescing operator, falls back to unknown. Why does this matter? An app on the App Store cannot be updated instantly. If the backend adds a new type tomorrow, say PODCAST, an older app would fail to decode, and the whole page would break. With this pattern, the old app just sees unknown and keeps working. This is a real production concern, and it is a good story to tell your audience.

---

Section three: protocols and generics. The idea is to program to an interface, not to a concrete type.

---

These are our repository protocols, from Repositories dot swift in AppCore. ItemRepository declares two functions, items and item. SessionRepository declares sessions and session. Notice three things. One: a protocol is a contract. The features only ever see these protocols. They never see a URL or an endpoint. Two: protocols can require Sendable, and their functions can be async throws. Three: look at the extension at the bottom. A protocol extension adds a convenience overload, session by id with no context, and every type that conforms to the protocol gets it for free. There are 27 protocols like this in AppCore.

---

One protocol, many implementations. The diagram shows the idea. A feature or a store depends on any SessionRepository, the protocol. There are two implementations. LiveSessionRepository, in the AppData module, makes real HTTP calls. FakeSessionRepository, in AppTesting, is used in tests and previews. The CompositionRoot is the only place in the app that picks the live one. The code below shows the live version: it holds a client and a base path, and its session function simply awaits the client's read call. The point to make here: because features depend on the protocol, we can swap the real network for a fake without changing a single line of feature code. Kiet will go deeper into how this shapes the architecture.

---

Generics. On the left, Lossy. It is a struct with a type parameter called Value, constrained to Decodable. Its initializer tries to decode a Value, and if that fails, try question mark turns the error into nil. So when we decode an array of Lossy days, one broken row becomes nil and gets dropped, while the rest of the list survives. It is the same never-fail-the-page idea as the unknown case, but written once and usable for any Decodable type. On the right, AppTabBarView is a generic SwiftUI view. Its ID type only needs to be Hashable, so a tab can be identified by an enum, a String, or a UUID. The takeaway: angle brackets with a constraint declare a type parameter. You write the code once, and the compiler type checks every use.

---

Some versus any. This is a common source of confusion, so explain it slowly. Some View is an opaque type. The function returns one specific concrete type, but hides which one from the caller. The compiler still knows it, so it can use static dispatch, which is fast. We use it 169 times, mostly for SwiftUI body properties. Any ProgressReportRepository is an existential. It can hold any type that conforms to the protocol, chosen at runtime. Swift stores it in a box and uses dynamic dispatch. We use it 215 times, for dependencies we want to swap, like live versus fake. Swift 6 makes you write the word any explicitly, so the cost is visible. The rule of thumb on the slide is the thing to remember: use some when you return it, use any when you store something swappable.

---

Section four: errors and optionals. In Swift, failure is part of the type, not an afterthought.

---

Domain errors as enums. PlaybackFailure lists every way a playback request can fail, in the app's own words. Premium required, which is the backend's 403 with code 2703, and the only failure that opens the paywall. Unverified, a 503, which is retryable and never shows the paywall. Not found, a 404, which is not retryable. And failed, for everything else, like being offline. Any type can conform to Error, and an enum is perfect for a closed list of failures. The HTTP codes are translated once, in the data layer, so the UI never sees a status code. And because it is Equatable, tests can simply expect that the error equals premium required.

---

Do and catch, with pattern matching. This loop is inside the flush function of ListeningReporter. It takes up to one hundred reports as a batch. The guard statement exits early if the batch is empty. Then, in the do block, it tries to send the batch, with try await. Now look at the two catch clauses. The first one only matches one specific error: ProgressReportFailure dot rejected. That is a 400, which means our app sent bad data. Retrying would send the same bytes again, so we log it and drop the batch. The bare catch matches everything else, like being offline, and simply returns, keeping the batch for next time. One do catch, two different policies. Also notice the key path, backslash dot id, used to collect the ids of the batch.

---

Typed throws, new in Swift 6. Normally, a throwing function throws any Error, so the caller's catch block receives an untyped error and has to cast it. With typed throws, you write the error type in parentheses after the throws keyword. Here, appGroup throws SXSharedError. Now the caller's catch receives an SXSharedError directly. It can switch over it exhaustively, with no casting. Use typed throws when the set of errors is small and closed. Most of our code still uses plain throws, because network errors are open ended. While you are on this slide, you can also point at the default argument, bundle equals main, the conditional cast with as question mark, and the ternary operator.

---

Optionals. A question mark after a type means a value of that type, or nothing, and the compiler forces you to handle the nothing case. Every line on the left is from our code. Guard let self exits early if self is gone. If let reading, using the shorthand from Swift 5.7, unwraps in a branch. Try question mark turns an error into nil. And double question mark supplies a default. We use guard let and if let about 220 times. What we never do in app code is the force unwrap, the exclamation mark, because it crashes when the value is nil. Our backend rules ban it outright, and tests only use it on fixed fixture values.

---

Section five: concurrency. This is the main event of the talk, so plan to spend the most time here.

---

Async and await. Here is LiveItemRepository's items function. The async keyword means the function can suspend, which means it can pause while waiting for the network without blocking a thread. The await keyword marks a possible suspension point, right at the call site, so a reader can see exactly where the code may pause. The code reads from top to bottom, like synchronous code. Before Swift 5.5, this would be a completion handler with a Result type, and several calls in a row turned into a pyramid of callbacks. Also note that async and throws compose: the function is async throws, and the call is try await.

---

The problem that concurrency safety solves: data races. Look at the code. A Counter class with a variable value. Two tasks both increment it at the same time, on different threads. Each one reads zero, adds one, and writes one. So the final value may be one instead of two. That is a data race, and it is one of the hardest bugs to reproduce. Swift 6's answer is to prove safety at compile time, with three tools. Sendable says a value is safe to pass between concurrency domains. An actor guarantees its state is touched by only one task at a time. And main actor means code runs on the main thread. In Swift 6 language mode, the snippet on this slide does not compile. A production bug becomes a build error.

---

Sendable. Every repository protocol requires Sendable. Every model struct and every error enum declares it too. Even closures can be marked Sendable, like the now closure that returns the current date. The rules are simple. A struct or enum whose fields are all Sendable can just declare Sendable. A class can only be Sendable if it is final and immutable, or isolated to an actor. A Sendable closure cannot capture mutable local state. And unchecked Sendable is the escape hatch, the trust me annotation. Remember the number from the start: zero uses in our repo. Our rule says you need a written proof to use it, and so far we have needed none.

---

Actors. ListeningReporter collects listening progress from the player, things like the user listened to this session for this many milliseconds, and sends it to the backend in batches of one hundred. Many events arrive concurrently, so it is declared as an actor instead of a class. An actor is like a class, but only one caller at a time can run inside it. Callers from outside must await. That protects the mutable state, the flushing set, without any locks. Now look at the report function. It is marked nonisolated, because it only builds a value and does not touch the actor's state, so it can be called synchronously, without await. The record function is isolated: it appends to the store and then awaits a flush.

---

Actor reentrancy. This is the most common mistake people make with actors, so make sure your audience gets it. An actor is not a lock. At every await inside an actor, the actor can start running another call. So any state you checked before the await may have changed after it. Look at how flush handles this. Before it awaits anything, it inserts the account into the flushing set. If the insert did not happen, because the account was already there, another flush is already running, so it returns immediately. Then defer removes the account on every exit path, whether the function returns normally, early, or after an error. The result: flush is safe to call from anywhere, any number of times, at once.

---

Main actor classes. PracticeStore is marked with at-MainActor and at-Observable. Main actor means every property and method runs on the main thread, so SwiftUI can read it safely. Observable and ObservationIgnored are macros. A macro generates code at compile time. Observable adds change tracking to every stored property, and ObservationIgnored opts one property out, like the repositories here, which never change. Notice the access control: public, private set. Anyone can read preferences and config, but only the store itself can write them. Stop here and hand over: how SwiftUI reacts to Observable is Khoa's part.

---

Structured concurrency with async let. This is PracticeStore's load function, and it packs three ideas into a few lines. Idea one: inside the task, two async let lines start two network requests immediately, as child tasks. The await on the tuple then collects both results. So the two requests run in parallel, not one after the other. Idea two: the task is stored in the reading property. If three screens call load at the same time, the first line sees a read already in flight and simply awaits the same task. Only one request goes out. Idea three: the weak self capture, plus the generation counter. When the user signs out, reset increments generation. If an old answer arrives late, the guard sees the generation changed and drops it. So a stale answer for a signed-out account lands nowhere.

---

AsyncStream. An async function gives you one value, later. An AsyncStream gives you many values, over time. You create it with a closure that receives a continuation. Yield pushes a value to the consumer, and finish ends the stream. On the consumer side, you use a for await loop, which reads just like a normal for loop, and it ends when the stream finishes. In BackendEntitlements, the stream yields unknown once and then finishes, because in our setup the backend is the only source of truth for entitlements. Think of AsyncStream as the async replacement for a publisher, or for a callback that fires many times.

---

The concurrency cheat sheet. This slide summarizes the whole section, so pause on it and let people read. To wait for one result, use async and await, like LiveItemRepository. To run things in parallel, use async let, like PracticeStore load. To share mutable state safely, use an actor, like ListeningReporter. For UI-facing state, use a main actor class, like PracticeStore and SessionPlayer. To pass values across tasks, make them Sendable, which every model and repository is. For many values over time, use AsyncStream. And to start work and keep a handle to it, store a Task, like PracticeStore's reading property.

---

Section six: modules and tooling. The last part is about how the code is organized and verified.

---

Modules and access control. The diagram shows our Swift package targets. The app target holds the main entry and the CompositionRoot. It depends on AppMain and AppData. AppMain depends on the features, like Home, Player and Course. The features depend on AppCore and AppDesign. AppData depends on AppCore. Each box is a separate module, compiled and tested on its own. Swift's access control works per module, so these boundaries are real. The table shows the levels. Public is visible to any module. Package, added in Swift 5.9, is visible only inside our own package, and we use it 171 times. Internal is the default, visible inside one module. Private and fileprivate limit to a scope or a file. Features expose their views as package, never public, and a feature can never import another feature.

---

Swift Testing. This is ListeningReporterTests. The at-Suite and at-Test attributes, and the hash-expect, are all macros. The test function is async, and it just works. Walk through it: create a fake repository and an in-memory store, append 150 reports, then await a flush on a real ListeningReporter. Then expect two batches, the first with one hundred reports and the second with fifty, and that the queue is empty. Point out how everything connects here: this test only works because the reporter depends on protocols, so we can pass a fake. Section three pays off. We have 78 test files, and the stop hook gate runs them before any change lands.

---

Macros we use every day. A macro generates Swift code at compile time. There are two kinds. Freestanding macros start with a hash sign, like hash Preview, which registers an Xcode preview, and hash expect, which builds an assertion that prints both sides when it fails. Attached macros start with an at sign and attach to a declaration, like Observable, ObservationIgnored, Test and Suite. The code below is a real preview from the Player feature: two versions of the top bar, one for a session and one for the timer. A good tip for your audience: in Xcode, you can right click any macro and choose Expand Macro, to see exactly what code it generates.

---

The recap. Six points. One: a strict compiler. Swift 6 mode plus warnings as errors turn bugs into build errors. Two: value types first. Structs and enums model our data, and impossible states cannot compile. Three: protocols. Features depend on contracts, so live and fake implementations are swappable. Four: errors are part of the type, with domain enums, catch patterns, typed throws, and no force unwraps. Five: concurrency, with async await, actors, the main actor, Sendable, and async let. Six: modules. Package access and separate targets keep the boundaries honest. If your audience remembers one sentence, make it this one: in Swift 6, the compiler is your teammate.

---

Finally, the hand over. Next up is Khoa, with iOS components and state management, showing State, Observable and Environment in action. Then Kiet, with the MVVM architecture, showing how views, models, stores and repositories fit together. Then open the floor for questions. That is the end of this lesson. Go through the slides once more on your own, read the speaker notes, and try explaining each concurrency slide out loud. Good luck with the presentation.
