// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:onlynote/data/local/database.dart' as _i1044;
import 'package:onlynote/data/repository/folder_repository.dart' as _i510;
import 'package:onlynote/data/repository/note_repository.dart' as _i277;
import 'package:onlynote/di/module.dart' as _i504;
import 'package:onlynote/domain/database/database.dart' as _i491;
import 'package:onlynote/domain/repository/folder_repository.dart' as _i264;
import 'package:onlynote/domain/repository/note_repository.dart' as _i234;
import 'package:onlynote/domain/usecase/add_note_usecase.dart' as _i153;
import 'package:onlynote/domain/usecase/delete_multiple_notes.dart' as _i805;
import 'package:onlynote/domain/usecase/delete_note_usecase.dart' as _i845;
import 'package:onlynote/domain/usecase/folder_usecases.dart' as _i940;
import 'package:onlynote/domain/usecase/get_note_usecase.dart' as _i513;
import 'package:onlynote/domain/usecase/move_note_to_folder_usecase.dart'
    as _i653;
import 'package:onlynote/domain/usecase/permanent_delete_notes_usecase.dart'
    as _i440;
import 'package:onlynote/domain/usecase/reorder_notes_usecase.dart' as _i660;
import 'package:onlynote/domain/usecase/restore_notes_usecase.dart' as _i648;
import 'package:onlynote/domain/usecase/show_notes_usecase.dart' as _i61;
import 'package:onlynote/domain/usecase/toggle_pin_usecase.dart' as _i116;
import 'package:onlynote/domain/usecase/update_note_usecase.dart' as _i211;
import 'package:onlynote/domain/usecase/usecase.dart' as _i731;
import 'package:onlynote/presentation/routes/routes.dart' as _i288;
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart'
    as _i460;
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_form/add_update_form_bloc.dart'
    as _i346;
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart'
    as _i256;
import 'package:onlynote/presentation/screens/home/bloc/multiple_delete/multiple_delete_bloc.dart'
    as _i367;
import 'package:onlynote/presentation/screens/note_detail/bloc/action/note_action_bloc.dart'
    as _i524;
import 'package:onlynote/presentation/screens/note_detail/bloc/detail/note_detail_bloc.dart'
    as _i273;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerCoreDependencies = _$RegisterCoreDependencies();
    gh.factory<_i288.AppRouter>(() => registerCoreDependencies.appRouter);
    gh.lazySingleton<_i264.FolderRepository>(
        () => _i510.FolderRepositoryImplementation());
    gh.lazySingleton<_i491.Database>(() => _i1044.DatabaseImplementing());
    gh.lazySingleton<_i234.NoteRepository>(
        () => _i277.NoteRepositoryImplementation(gh<_i491.Database>()));
    gh.factory<_i940.DeleteFolderUsecase>(() => _i940.DeleteFolderUsecase(
          gh<_i264.FolderRepository>(),
          gh<_i234.NoteRepository>(),
        ));
    gh.factory<_i940.CreateFolderUsecase>(
        () => _i940.CreateFolderUsecase(gh<_i264.FolderRepository>()));
    gh.factory<_i940.RenameFolderUsecase>(
        () => _i940.RenameFolderUsecase(gh<_i264.FolderRepository>()));
    gh.factory<_i805.DeleteMultipleNotesUsecase>(
        () => _i805.DeleteMultipleNotesUsecase(gh<_i234.NoteRepository>()));
    gh.factory<_i660.ReorderNotesUsecase>(
        () => _i660.ReorderNotesUsecase(gh<_i234.NoteRepository>()));
    gh.factory<_i440.PermanentDeleteNotesUsecase>(
        () => _i440.PermanentDeleteNotesUsecase(gh<_i234.NoteRepository>()));
    gh.factory<_i845.DeleteNoteUsecase>(
        () => _i845.DeleteNoteUsecase(gh<_i234.NoteRepository>()));
    gh.factory<_i653.MoveNoteToFolderUsecase>(
        () => _i653.MoveNoteToFolderUsecase(gh<_i234.NoteRepository>()));
    gh.factory<_i648.RestoreNotesUsecase>(
        () => _i648.RestoreNotesUsecase(gh<_i234.NoteRepository>()));
    gh.factory<_i116.TogglePinUsecase>(
        () => _i116.TogglePinUsecase(gh<_i234.NoteRepository>()));
    gh.factory<_i211.UpdateNoteUsecase>(
        () => _i211.UpdateNoteUsecase(gh<_i234.NoteRepository>()));
    gh.factory<_i153.AddNoteUsecase>(
        () => _i153.AddNoteUsecase(gh<_i234.NoteRepository>()));
    gh.factory<_i513.GetNoteUsecase>(
        () => _i513.GetNoteUsecase(gh<_i234.NoteRepository>()));
    gh.factory<_i273.NoteDetailBloc>(() => _i273.NoteDetailBloc(
          gh<_i731.GetNoteUsecase>(),
          gh<_i731.UpdateNoteUsecase>(),
        ));
    gh.factory<_i460.AddUpdateBloc>(() => _i460.AddUpdateBloc(
          gh<_i731.AddNoteUsecase>(),
          gh<_i731.UpdateNoteUsecase>(),
        ));
    gh.factory<_i367.MultipleDeleteBloc>(
        () => _i367.MultipleDeleteBloc(gh<_i731.DeleteMultipleNotesUsecase>()));
    gh.factory<_i61.ShowAllNotesUsecase>(() => _i61.ShowAllNotesUsecase(
          gh<_i234.NoteRepository>(),
          gh<_i264.FolderRepository>(),
        ));
    gh.factory<_i346.AddUpdateFormBloc>(
        () => _i346.AddUpdateFormBloc(gh<_i460.AddUpdateBloc>()));
    gh.factory<_i524.NoteActionBloc>(
        () => _i524.NoteActionBloc(gh<_i731.DeleteNoteUsecase>()));
    gh.factory<_i256.HomeBloc>(() => _i256.HomeBloc(
          gh<_i731.ShowAllNotesUsecase>(),
          gh<_i731.AddNoteUsecase>(),
          gh<_i731.ReorderNotesUsecase>(),
          gh<_i731.TogglePinUsecase>(),
          gh<_i731.RestoreNotesUsecase>(),
          gh<_i731.PermanentDeleteNotesUsecase>(),
          gh<_i731.CreateFolderUsecase>(),
          gh<_i731.RenameFolderUsecase>(),
          gh<_i731.DeleteFolderUsecase>(),
          gh<_i731.MoveNoteToFolderUsecase>(),
        ));
    return this;
  }
}

class _$RegisterCoreDependencies extends _i504.RegisterCoreDependencies {}
