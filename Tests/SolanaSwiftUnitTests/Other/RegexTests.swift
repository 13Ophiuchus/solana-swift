import Foundation
import Testing

struct RegexTests {
    @Test func pubkeyRegex() throws {
        let regex = NSRegularExpression.publicKey
        #expect(regex.matches("3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG"))
        #expect(regex.matches("5iqF9UNh6AB7hPkJiGFLixJuPeMqp9VVq7iJ9t8c3ZF"))
        #expect(regex.matches("CEUFMRm2cdr6UqCfPXAQnWqnndNVWuyk3QiC5gBN2k5"))
        #expect(regex.matches("JnfsZ5HahZnvnKsRZMsAf3D92e92C33NyufnrqAt2WL"))
        #expect(regex.matches("299wbEddCsswPqT9gv2gNAE6bxETMBKVuTrwdwtgvSMV"))
        #expect(regex.matches("2NrFPGGW8BKKU8hD48G3HhTXXRycd7fYbUKNEnmeLA97"))
        #expect(regex.matches("2kAQ6EL8Xhp1VXjM6JmwzVexFkWHYJoLnJNHRMWdkHKE"))
        #expect(regex.matches("36sp9nNMm4jja1h8wcvBYKyUYaqvHV1sfuBSJ5ddjcMd"))
        #expect(regex.matches("3Jc5CLBGd9dPfiXQ6K6ANu69g9mg9gHyKXxA2Gsk9qFa"))
        #expect(regex.matches("41r5NV6uj386xwXmeKwQ8V6mTH6Y4aouth5yQzeReFJt"))

        #expect(!(regex.matches("3h1zGmCwsRJnVk5BuR")))
        #expect(!(regex.matches("41r5NV6uj386xwXmeKwQ8V6mTH6Y4aouth5yQzeReFJt333")))
        #expect(!(regex.matches("41r5NV6uj386xwXm-KwQ8V6mTH6Y4+outh5yQzeReFJt")))
    }
}
