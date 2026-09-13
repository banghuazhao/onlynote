import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onlynote/presentation/routes/routes.dart';

class NoteAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NoteAppBar({
    super.key,
    this.autoImplementLeading = true,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.systemUiOverlayStyle,
  }) : assert(
          title == null || titleWidget == null,
          'Provide either title or titleWidget, not both.',
        );

  final bool autoImplementLeading;
  final String? title;

  /// An interactive title — a picker, say — for screens where the title is
  /// more than a label. Takes precedence over [title].
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final SystemUiOverlayStyle? systemUiOverlayStyle;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      systemOverlayStyle: systemUiOverlayStyle ??
          (Theme.of(context).brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent),
      leadingWidth: 60,
      leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: leading ??
              (autoImplementLeading
                  ? IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                      onPressed: context.router.maybePop,
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  : const SizedBox.shrink())),
      titleSpacing: titleWidget == null ? null : 0,
      title: titleWidget ?? (title == null ? null : Text(title!)),
      actionsPadding: const EdgeInsets.only(right: 12),
      actions: actions == null
          ? null
          : [
              for (var index = 0; index < actions!.length; index++)
                Padding(
                  padding: EdgeInsets.only(
                      right: index == actions!.length - 1 ? 0 : 4),
                  child: actions![index],
                ),
            ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
