import 'package:flutter_boilerplate/data/api/api_client.dart';
import 'package:flutter_boilerplate/data/api/endpoints.dart';
import 'package:get/get.dart';

class BazarTrackApi {
  final ApiClient client;
  BazarTrackApi({required this.client});

  Future<Response> login(String email, String password) async {
    final res = await client.postData(Endpoints.login, {
      'email': email,
      'password': password,
    });
    if (res.isOk && res.body is Map && res.body['token'] != null) {
      client.updateHeader(res.body['token']);
    }
    return res;
  }

  Future<Response> logout() => client.postData(Endpoints.logout, {});
  Future<Response> me() => client.getData(Endpoints.me);
  Future<Response> refresh() => client.postData(Endpoints.refresh, {});

  // Orders
  Future<Response> orders() => client.getData(Endpoints.orders);
  Future<Response> createOrder(Map<String, dynamic> data) => client.postData(Endpoints.orders, data);
  Future<Response> order(int id) => client.getData(Endpoints.order(id));
  Future<Response> updateOrder(int id, Map<String, dynamic> data) => client.putData(Endpoints.order(id), data);
  Future<Response> deleteOrder(int id) => client.deleteData(Endpoints.order(id));
  Future<Response> assignOrder(int id, Map<String, dynamic> data) => client.postData(Endpoints.assignOrder(id), data);
  Future<Response> completeOrder(int id, Map<String, dynamic> data) => client.postData(Endpoints.completeOrder(id), data);

  // Order items
  Future<Response> orderItems() => client.getData(Endpoints.orderItems);
  Future<Response> itemsOfOrder(int orderId) => client.getData(Endpoints.itemsOfOrder(orderId));
  Future<Response> orderItem(int orderId, int id) => client.getData(Endpoints.orderItem(orderId, id));
  Future<Response> createItem(Map<String, dynamic> data) => client.postData(Endpoints.orderItems, data);
  Future<Response> updateItem(int orderId, int id, Map<String, dynamic> data) => client.putData(Endpoints.orderItem(orderId, id), data);
  Future<Response> deleteItem(int orderId, int id) => client.deleteData(Endpoints.orderItem(orderId, id));

  // Payments
  Future<Response> payments() => client.getData(Endpoints.payments);
  Future<Response> createPayment(Map<String, dynamic> data) => client.postData(Endpoints.payments, data);

  // Wallet
  Future<Response> wallet(int userId) => client.getData(Endpoints.wallet(userId));
  Future<Response> walletTransactions(int userId) => client.getData(Endpoints.walletTransactions(userId));

  // History
  Future<Response> history() => client.getData(Endpoints.history);
  Future<Response> historyByEntity(String entity, int id) => client.getData(Endpoints.historyByEntity(entity, id));
  Future<Response> createHistory(Map<String, dynamic> data) => client.postData(Endpoints.history, data);
  Future<Response> deleteHistory(int id) => client.deleteData('${Endpoints.history}/$id');

  // Analytics
  Future<Response> dashboard() => client.getData(Endpoints.analyticsDashboard);
  Future<Response> reports() => client.getData(Endpoints.analyticsReports);
}
