import 'package:http_interceptor/http_interceptor.dart';

import 'package:DRPublic/api/auth/authenticate_interceptor.dart';

class InterceptorHelper {
  final client = InterceptedClient.build(
    interceptors: [AuthenticateInterceptor()],
    retryPolicy: ExpiredTokenRetryPolicy(),
  );
}
