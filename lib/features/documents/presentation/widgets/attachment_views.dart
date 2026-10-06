import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:paw_vault/core/presentation/widgets/full_screen_image.dart';
import 'package:paw_vault/features/documents/domain/entities/document_attachment.dart';
import 'package:paw_vault/features/documents/domain/services/document_file_opener.dart';

/// Shared views for attached files.
///
/// Documents and Smart Input both list attachments — a scanned analysis is
/// describing a document, and it keeps the same files — so these live in one
/// place. They were duplicated before, and drifted: only one of the two had a
/// loading placeholder, so the other looked empty while a photo downloaded.

/// Says that something carries files, without waiting for any of them.
///
/// No network, so it is right the instant the row paints — including for a
/// PDF, which has no thumbnail to show.
class AttachmentLabel extends StatelessWidget {
  const AttachmentLabel({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.attach_file,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          count == 1 ? '1 file' : '$count files',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// One attached file, full width: an image inline and tappable to full
/// screen, anything else behind a button that opens it.
class AttachmentPreview extends StatelessWidget {
  const AttachmentPreview({
    required this.attachment,
    required this.fileOpener,
    super.key,
  });

  static const _previewHeight = 220.0;

  final DocumentAttachment attachment;
  final DocumentFileOpener fileOpener;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!attachment.isImage) {
      return OutlinedButton.icon(
        onPressed: () => fileOpener.open(attachment.fileUrl),
        icon: const Icon(Icons.open_in_new),
        label: Text(
          attachment.fileExtension.isEmpty
              ? 'Open file'
              : 'Open ${attachment.fileExtension.toUpperCase()}',
        ),
      );
    }

    return GestureDetector(
      onTap: () => showFullScreenImage(
        context,
        CachedNetworkImageProvider(attachment.fileUrl.toString()),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: attachment.fileUrl.toString(),
          height: _previewHeight,
          width: double.infinity,
          fit: BoxFit.cover,
          // Without this the view was an empty box for the whole download,
          // so the record looked as though nothing was attached to it.
          placeholder: (context, _) => Container(
            height: _previewHeight,
            color: theme.colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          // The default half-second fade is dead time on top of the download.
          fadeInDuration: const Duration(milliseconds: 120),
          errorWidget: (context, _, __) => Container(
            height: _previewHeight,
            color: theme.colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );
  }
}

/// A small thumbnail of [attachment], for a list row.
///
/// Doing this in the row is what makes opening the record feel quick: a
/// mounted image widget really drives the download and fills the shared disk
/// cache, so the full preview usually reads from disk.
///
/// [fallback] stands in both while the image loads and if it cannot be
/// loaded at all — a broken-image box in every row is worse than none, and a
/// fetch that simply hangs must not leave an empty slot either. Callers whose
/// slot would otherwise look blank should pass something to put there.
class AttachmentThumbnail extends StatefulWidget {
  const AttachmentThumbnail({
    required this.attachment,
    this.size = 40,
    this.fallback,
    super.key,
  });

  final DocumentAttachment attachment;
  final double size;
  final Widget? fallback;

  @override
  State<AttachmentThumbnail> createState() => _AttachmentThumbnailState();
}

class _AttachmentThumbnailState extends State<AttachmentThumbnail> {
  bool _failed = false;

  @override
  void didUpdateWidget(AttachmentThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachment != widget.attachment) {
      _failed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return widget.fallback ??
          SizedBox(width: widget.size, height: widget.size);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: CachedNetworkImage(
        imageUrl: widget.attachment.fileUrl.toString(),
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        // Decoded small: a row needs 40 logical pixels, not a whole photo.
        memCacheWidth: 160,
        placeholder: (context, _) =>
            widget.fallback ??
            ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: SizedBox(width: widget.size, height: widget.size),
            ),
        errorWidget: (context, _, __) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_failed) {
              setState(() => _failed = true);
            }
          });
          return SizedBox(width: widget.size, height: widget.size);
        },
      ),
    );
  }
}
