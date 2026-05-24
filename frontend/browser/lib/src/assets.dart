import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'errors.dart';

/// Агресивний кеш статичних ресурсів вебу для .rice (іконки, зображення).
class RiceCacheManager extends CacheManager {
  RiceCacheManager._()
      : super(
          Config(
            _kCacheKey,
            stalePeriod: const Duration(days: 365),
            maxNrOfCacheObjects: 800,
          ),
        );

  static const _kCacheKey = 'rice_bard_web_static';

  static final RiceCacheManager instance = RiceCacheManager._();
}

/// Растрове зображення з мережі через [RiceCacheManager].
class RiceCachedImage extends StatelessWidget {
  const RiceCachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: RiceCacheManager.instance,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) =>
          placeholder ?? const Center(child: CircularProgressIndicator()),
      errorWidget: (_, __, ___) =>
          errorWidget ?? const Icon(Icons.broken_image_outlined),
    );
  }
}

/// SVG з мережі (окремий шар кешу браузера; растрові URL — через [RiceCachedImage]).
class RiceCachedSvg extends StatelessWidget {
  const RiceCachedSvg({
    super.key,
    required this.svgUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final String svgUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.network(
      svgUrl,
      width: width,
      height: height,
      fit: fit,
      placeholderBuilder: (_) =>
          const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Примусово завантажує ресурс у [RiceCacheManager].
Future<FileInfo> ricePrefetchAsset(
  String url, {
  Map<String, String>? headers,
}) async {
  try {
    return RiceCacheManager.instance.downloadFile(
      url,
      authHeaders: headers,
    );
  } catch (e, st) {
    Error.throwWithStackTrace(
      RiceBrowserException('ricePrefetchAsset: $url', cause: e),
      st,
    );
  }
}
