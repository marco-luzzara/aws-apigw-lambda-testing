package org.example.ui.lambda;

import com.amazonaws.services.lambda.runtime.events.APIGatewayCustomAuthorizerEvent;
import com.amazonaws.services.lambda.runtime.events.IamPolicyResponseV1;
import com.auth0.jwt.JWT;
import org.example.ui.lambda.model.InvocationWrapper;
import org.example.ui.lambda.model.LoginResponse;
import org.example.ui.lambda.model.UserLoginRequest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.core.internal.http.loader.DefaultSdkHttpClientBuilder;
import software.amazon.awssdk.services.cognitoidentityprovider.CognitoIdentityProviderClient;
import software.amazon.awssdk.services.iam.IamClient;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.function.Supplier;

@Configuration
public class UserLambda {
    @Bean
    public Function<InvocationWrapper<UserLoginRequest>, LoginResponse> loginUser() {
        return (loginRequest) -> {
            var clientId = System.getProperty("aws.cognito.user_pool_client_id");
            var userPoolId = System.getProperty("aws.cognito.user_pool_id");

            try (var cognitoClient = CognitoIdentityProviderClient.create()) {
                var authResponse = cognitoClient.initiateAuth(b -> b
                                .clientId(clientId)
                                .authFlow("USER_PASSWORD_AUTH")
                                .authParameters(
                                        Map.of(
                                                "USERNAME", loginRequest.body().username(),
                                                "PASSWORD", loginRequest.body().password()
                                        )
                                ));

                return new LoginResponse(
                        authResponse.authenticationResult().accessToken(),
                        authResponse.authenticationResult().idToken());
            }
        };
    }

    @Bean
    public Function<APIGatewayCustomAuthorizerEvent, IamPolicyResponseV1> authorize() {
        return (event) -> {
            var authToken = event.getHeaders().get("Authorization").substring("Bearer ".length()); // .getAuthorizationToken() is not supported in Localstack
            var jwt = JWT.decode(authToken);
            var principalId = jwt.getSubject();

            return IamPolicyResponseV1.builder()
                    .withPrincipalId(principalId)
                    .withPolicyDocument(IamPolicyResponseV1.PolicyDocument.builder()
                            .withVersion("2012-10-17")
                            .withStatement(List.of(IamPolicyResponseV1.Statement.builder()
                                    .withAction("execute-api:Invoke")
                                    .withEffect("Allow")
                                    .withResource(List.of(event.getMethodArn()))
                                    .build()))
                            .build())
                    .build();
        };
    }

    @Bean
    public Supplier<String> getUser() {
        return () -> "test2";
    }
}
