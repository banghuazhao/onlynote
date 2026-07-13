import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onlynote/presentation/routes/routes.dart';

class NoteAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NoteAppBar({
    super.key,
    this.autoImplementLeading = true,
    this.title,
    this.actions,
    this.leading,
    this.systemUiOverlayStyle,
  });

  final bool autoImplementLeading;
  final String? title;
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
      leading: leading ??
          (autoImplementLeading
              ? IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: context.router.maybePop,
                  icon: const Icon(Icons.arrow_back_rounded),
                )
              : null),
      title: title == null ? null : Text(title!),
      actionsPadding: const EdgeInsets.only(right: 16),
      actions: actions == null
          ? null
          : [
              for (var index = 0; index < actions!.length; index++)
                Padding(
                  padding: EdgeInsets.only(
                      right: index == actions!.length - 1 ? 0 : 8),
                  child: actions![index],
                ),
            ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
