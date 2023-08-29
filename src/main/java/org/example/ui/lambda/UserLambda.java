package org.example.ui.lambda;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.function.Supplier;

@Configuration
public class UserLambda {
    @Bean
    public Supplier<String> testFunction() {
        return () -> "test";
    }

    @Bean
    public Supplier<String> testFunction2() {
        return () -> "test2";
    }

//    @Bean
//    public Function<Message<UserGetRequest>, Message<UserInfo>> getUser() {
//        return userGetRequest -> this.userService.getUser(userGetRequest.getPayload().id())
//                .map(userInfo -> MessageBuilder.withPayload(userInfo).build())
//                .orElseGet(() -> MessageBuilder
//                        .withPayload(new UserInfo(-1, ""))
//                        .setHeader("X-Amz-Function-Error", "No value present")
//                        .build());
//    }
}
