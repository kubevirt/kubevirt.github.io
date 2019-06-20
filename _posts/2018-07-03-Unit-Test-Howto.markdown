---
layout: post
author: yuvalif
description: This post tries to demystify some of our unit test mechanism, hopefully will make it easier to write more tests and increase our code coverage!
navbar_active: Blogs
pub-date: July 3
pub-year: 2018
category: news
comments: true
---

There are [way too many reasons](https://blog.codinghorror.com/i-pity-the-fool-who-doesnt-write-unit-tests/) to write unit tests, but my favorite one is: the freedom to hack, modify and improve the code without fear, and get quick feedback that you are on the right track.

Of course, writing good integration tests (the stuff under the [tests](https://github.com/kubevirt/kubevirt/tree/master/tests) directory) is the best way to validate that everything works, but unit tests has great value as:
- They are much faster to run (~30 seconds in our case)
- You get nice coverage reports with [coveralls](https://coveralls.io/github/kubevirt/kubevirt)
- No need to: `make cluster up/sync`
- Cover corner cases and easier to debug

> Some Notes:
> - We use same frameworks (ginkgo, gomega) for unit testing and integration testing, which means that with the same learning curve, you can develop much more!
> - "Bang for the Buck" - it usually takes 20% of the time to get to 80% coverage, and 80% of the time to get to 100%. Which mean that you have to use common sense when improving coverage - some code is just fine with 80% coverage (e.g. large files calling some other APIs with little logic), and other would benefit from getting close to 100% (e.g. complex core functionality handling lots of error cases)
> - Follow the ["boy (or girl) scout rule"](http://programmer.97things.oreilly.com/wiki/index.php/The_Boy_Scout_Rule) - every time you enhance/fix some code, add more testing around the existing code as well
> - Avoid "white box testing", as this will cause endless maintenance of the test code. Best way to assure that, is to put the test code under a different package than the code under test
> - Explore coveralls. Not only it will show you the coverage and the overall trend, it will also help you understand which tests are missing. When drilling down into a file, you can see hits per line, and make better decision on what needs to be covered next

# Frameworks
There are several frameworks we use to write unit tests:
- The tests themselves are written using [ginkgo](https://github.com/onsi/ginkgo), which is a [Behavior-Driven Development (BDD)](https://en.wikipedia.org/wiki/Behavior-driven_development) framework
- The library used for assertions in the tests is [gomega](https://github.com/onsi/gomega). It has a very rich set of matchers, so, before you write you own code around the "equal" matcher, check [here](http://onsi.github.io/gomega/#provided-matchers) to see if there is a more expressive assertion you can use
- We use [GoMock](https://github.com/golang/mock) to generate mocks for the different kubevirt interfaces and objects. The command `make generate` will (among other things) create a [file](https://github.com/kubevirt/kubevirt/blob/master/staging/src/kubevirt.io/client-go/kubecli/generated_mock_kubevirt.go) holding the mocked version of our objects and interfaces
  - Many examples exist in our code on how to use this framework
  - Also see [here](https://github.com/golang/mock/tree/master/sample) for sample code from GoMock
- If you need mocks for k8s objects and interfaces, use their framework. They have a tool called [client-gen](https://github.com/kubernetes/code-generator), which generates both the code and the mocks based on the defined APIs
  - The generated mock interfaces and objects of the k8s client are [here](https://github.com/kubernetes/client-go/blob/master/kubernetes/fake/clientset_generated.go). Note that they a use a different mechanism to control the mocked behavior than the one used in GoMock
  - Mocked actions are more are [here](https://github.com/kubernetes/client-go/tree/master/testing)
- Unit test utilities are placed under [testutils](https://github.com/kubevirt/kubevirt/tree/master/pkg/testutils)
- Some integration test utilities are also useful for unit testing, see this [file](https://github.com/kubevirt/kubevirt/blob/master/tests/utils.go)
- When testing interfaces, a mock HTTP server is usually needed. For that we use the [golang httptest package](https://golang.org/pkg/net/http/httptest/)
  - gomega also has a package called [ghttp](http://onsi.github.io/gomega/#ghttp-testing-http-clients) that could be used for same purpose

# Best Practices and Tips
## ginkgo
- Don't mix setup and tests, use BeforeEach/JustBeforeEach for setup and It/Specify for tests
- Don't write setup/cleanup code under Describe/Context clause, which is not inside BeforeEach/AfterEach etc.
- Make sure that any state change inside an "It" clause, that may impact other tests, is reverted in "AfterEach"
- Don't assume the "It" clauses, which are at the same level, are invoked in any specific order
## gomega
Be verbose and use specific matchers. For example, to check that an array has N elements, you can use:
```
Expect(len(arr)).To(Equal(N))
```
But a better way would be:
```
Expect(arr).To(HaveLen(N))
```
## Function Override
Sometimes the code under test is invoking a function which is not mocked. In most cases, this is an indication that the code needs to be refactored, so this function, or its return values, will be passed as part of the API of the code being tested.
However, if this refactoring is not possible (or too costly), you can inject your own implementation of this function. The original function should be defined as a closure, and assigned to a global variable. Since functions are 1st class citizens in go, you can assign your implementation to that function variable. More detailed example is [here](https://gist.github.com/yuvalif/006c48c563f264041f4ada5f90ddfd0c)
