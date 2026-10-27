import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/api/api_providers.dart';

import '../../core/theme/app_colors.dart';

class ReceiptImage extends ConsumerWidget {
  const ReceiptImage({
    required this.receiptUrl,
    super.key,
    this.size = 52,
    this.onTap,
  });

  final String? receiptUrl;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = receiptUrl;
    if (url == null || url.isEmpty) {
      return _ReceiptPlaceholder(size: size);
    }

    final image = _imageFor(url, ref);
    return Semantics(
      button: onTap != null,
      image: true,
      label: 'রসিদ দেখুন',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: size, height: size, child: image),
        ),
      ),
    );
  }

  Widget _imageFor(String url, WidgetRef ref) {
    if (url.startsWith('file://')) {
      return Image.file(
        File(Uri.parse(url).toFilePath()),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _ReceiptPlaceholder(size: size),
      );
    }
    if (url.startsWith('data:image/')) {
      final encoded = url.split(',').last;
      return Image.memory(
        base64Decode(encoded),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _ReceiptPlaceholder(size: size),
      );
    }
    return FutureBuilder<String?>(
      future: ref.read(apiSessionStoreProvider).readToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const ReceiptImageShimmer();
        }
        final token = snapshot.data;
        if (token == null || token.isEmpty) return _ReceiptPlaceholder(size: size);
        return CachedNetworkImage(
          imageUrl: url,
          httpHeaders: {'Authorization': 'Bearer $token'},
          fit: BoxFit.cover,
          placeholder: (_, _) => const ReceiptImageShimmer(),
          errorWidget: (_, _, _) => _ReceiptPlaceholder(size: size),
        );
      },
    );
  }
}

class ReceiptImageShimmer extends StatelessWidget {
  const ReceiptImageShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface3,
      highlightColor: Colors.white,
      child: const ColoredBox(color: AppColors.surface3),
    );
  }
}

class _ReceiptPlaceholder extends StatelessWidget {
  const _ReceiptPlaceholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColors.surface3,
      alignment: Alignment.center,
      child: const Icon(Icons.receipt_long_outlined, color: AppColors.text3),
    );
  }
}
