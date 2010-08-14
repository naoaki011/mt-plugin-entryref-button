package MT::Plugin::EntityRefButton;

use strict;
use MT::Plugin;
@MT::Plugin::EntityRefButton::ISA = qw( MT::Plugin );

use vars qw( $VERSION $PLUGIN_NAME );
$PLUGIN_NAME = 'EntityRefButton';
$VERSION = '0.2.2';

use MT;

my $plugin = MT::Plugin::EntityRefButton->new({
    name => $PLUGIN_NAME,
    version => $VERSION,
    description => '<MT_TRANS phrase=\'This plugin adds a convert button to the entry body and the extended body fields on the edit entry screen, which converts special characters to character entity references.\'>',
    author_name => 'M-Logic, Inc.',
    author_link => 'http://labs.m-logic.jp/',
    doc_link => 'http://labs.m-logic.jp/plugins/entityrefbutton/docs/entityrefbutton.html',
    l10n_class => 'EntityRefButton::L10N',
    blog_config_template => \&template,
    settings => new MT::PluginSettings([
        ['entity_ref_convert_space', { Default => 1 }],
    ]),
});
MT->add_plugin($plugin);
if(is_mt33()) {
    #MT3.x / MTE1.5
    MT->add_callback('MT::App::CMS::AppTemplateSource.edit_entry', 9, $plugin, sub { transform('edit_entry', @_) });
    MT->add_callback('MT::App::CMS::AppTemplateSource.bm_entry', 9, $plugin, sub { transform('bm_entry', @_) });
    MT->add_callback('MT::App::CMS::AppTemplateParam.edit_entry', 9, $plugin, sub { mod_params('edit_entry', @_) });
    MT->add_callback('MT::App::CMS::AppTemplateParam.bm_entry', 9, $plugin, sub { mod_params('bm_entry', @_) });
}
elsif(is_mt40()) {
    # MT4
    MT->add_callback('MT::App::CMS::template_source.edit_entry', 9, $plugin, sub { transform_mt4(@_) });
    MT->add_callback('MT::App::CMS::template_param.edit_entry', 9, $plugin, sub { mod_params_mt4(@_) });
}
elsif(is_mt41() || is_mt42()) {
    # MT4.1
    MT->add_callback('MT::App::CMS::template_source.archetype_editor', 9, $plugin, sub { transform_mt4(@_) });
    MT->add_callback('MT::App::CMS::template_param.edit_entry', 9, $plugin, sub { mod_params_mt4(@_) });
}
# NOTE: Lookbehind longer than 255 not implemented in regex;

my %TEMPLATES = (
	       edit_entry => [
			      # script
			      {
			       pattern_s => '<div id="edit-entry">',
			       pattern_e => '\n',
			       replacement => <<'REPLACEMENT_END'

<script type="text/javascript">
<!--
function getCvtSpace() {
    return '<TMPL_VAR NAME=ENTITY_REF_CONVERT_SPACE>';
}

function convertToCharEntityRef(e) {
    if(!canFormat) return;
    var str = getSelected(e);
    if(str) {
        str = str.replace(/&/g, "&amp;");
        str = str.replace(/</g, "&lt;");
        str = str.replace(/>/g, "&gt;");
        str = str.replace(/"/g, "&quot;");
        if(getCvtSpace()) {
            str = str.replace(/ /g, "&nbsp;");
        }
        setSelection(e, str);
    }
    return false;
}
//-->
</script>
REPLACEMENT_END
,
			      },
			      # body
			      {
                               pattern_s => <<'PATTERN_END'
        write\(.+?"Quote"(?: escape="singlequotes")??>".+?entry_form\.text.+?\);
PATTERN_END
,
			       pattern_e => '\s+?\}\n\}',
			       replacement => <<'REPLACEMENT_END'
        write('<img title="<TMPL_VAR NAME=ENTITY_REF_BUTTON_LABEL>" onclick="return convertToCharEntityRef(document.entry_form.text)" src="<TMPL_VAR NAME=STATIC_URI>plugins/EntityRefButton/images/formatting-icons/ref.gif" alt="<TMPL_VAR NAME=ENTITY_REF_BUTTON_LABEL>" width="26" height="19" />');
REPLACEMENT_END
,
			      },
			      # extended body
			      {
			       pattern_s => <<'PATTERN_END'
        write\(.+?"Quote">".+?entry_form\.text_more.+?\);
PATTERN_END
,
			       pattern_e => '\s+?\}\n\}',
			       replacement => <<'REPLACEMENT_END'
        write('<img title="<TMPL_VAR NAME=ENTITY_REF_BUTTON_LABEL>" onclick="return convertToCharEntityRef(document.entry_form.text_more)" src="<TMPL_VAR NAME=STATIC_URI>plugins/EntityRefButton/images/formatting-icons/ref.gif" alt="<TMPL_VAR NAME=ENTITY_REF_BUTTON_LABEL>" width="26" height="19" />');
REPLACEMENT_END
			      },
			     ],
	       bm_entry => [
			    # script
			    {
                             pattern_s => '<div id="quickpost">',
			     pattern_e => '\n',
			     replacement => <<'REPLACEMENT_END'

<script type="text/javascript">
<!--
function getCvtSpace() {
    var ar = new Array();
<TMPL_LOOP NAME=BLOG_LOOP>
    ar[<TMPL_VAR NAME=BLOG_ID>] = '<TMPL_VAR NAME=ENTITY_REF_CONVERT_SPACE>';
</TMPL_LOOP>
    var f = document.entry_form;
    return ar[f.blog_id.options[f.blog_id.selectedIndex].value];
}

function convertToCharEntityRef(e) {
    if(!canFormat) return;
    if(validate) {
        if(!validate(document.entry_form)) {
            return;
        }
    }
    var str = getSelected(e);
    if(str) {
        str = str.replace(/&/g, "&amp;");
        str = str.replace(/</g, "&lt;");
        str = str.replace(/>/g, "&gt;");
        str = str.replace(/"/g, "&quot;");
        if(getCvtSpace()) {
            str = str.replace(/ /g, "&nbsp;");
        }
        setSelection(e, str);
    }
    return false;
}
//-->
</script>
REPLACEMENT_END
,
			    },
			    # body
			    {
                               pattern_s => <<'PATTERN_END'
        write\(.+?"Quote"(?: escape="singlequotes")??>".+?entry_form\.text.+?\);
PATTERN_END
,
			     pattern_e => '\s+\}\n\}',
			     replacement => <<'REPLACEMENT_END'
        write('<a title="<TMPL_VAR NAME=ENTITY_REF_BUTTON_LABEL>" href="#" onclick="return convertToCharEntityRef(document.entry_form.text)"><img src="<TMPL_VAR NAME=ENTITY_REF_BUTTON_ICON>" alt="<TMPL_VAR NAME=ENTITY_REF_BUTTON_LABEL>" width="<TMPL_VAR NAME=ENTITY_REF_BUTTON_ICON_WIDTH>" height="<TMPL_VAR NAME=ENTITY_REF_BUTTON_ICON_HEIGHT>" /></a>');
REPLACEMENT_END
,
			    },
			    # extended body
			    {
			       pattern_s => <<'PATTERN_END'
        write\(.+?"Quote">".+?entry_form\.text_more.+?\);
PATTERN_END
,
			     pattern_e => '\s+\}\n\}',
			     replacement => <<'REPLACEMENT_END'
        write('<a title="<TMPL_VAR NAME=ENTITY_REF_BUTTON_LABEL>" href="#" onclick="return convertToCharEntityRef(document.entry_form.text_more)"><img src="<TMPL_VAR NAME=ENTITY_REF_BUTTON_ICON>" alt="<TMPL_VAR NAME=ENTITY_REF_BUTTON_LABEL>" width="<TMPL_VAR NAME=ENTITY_REF_BUTTON_ICON_WIDTH>" height="<TMPL_VAR NAME=ENTITY_REF_BUTTON_ICON_HEIGHT>" /></a>');
REPLACEMENT_END
,
			    },
			   ],
	      );


sub instance { $plugin; }

sub is_mt33 {
    return (substr(MT->version_number, 0, 3) eq '3.3');
}

sub is_mt40 {
    return (substr(MT->version_number, 0, 3) eq '4.0');
}

sub is_mt41 {
    return (substr(MT->version_number, 0, 3) eq '4.1');
}

sub is_mt42 {
    return (substr(MT->version_number, 0, 3) eq '4.2');
}

sub log {
    my $plugin = shift;
    my ($msg) = @_;
    use MT::Log;
    my $log = MT::Log->new;
    if(defined($msg)) {
        $log->message($msg);
    }
    $log->save or die $log->errstr;
}

sub mod_params {
  my $template_name = shift;
  my ($eh, $app, $param, $tmpl) = @_;
  $param->{entity_ref_button_label} = $plugin->translate('Convert to character entity reference');
  if($template_name eq 'edit_entry') {
      $param->{entity_ref_convert_space} = $plugin->entity_ref_convert_space($app->blog->id);
  }
  elsif($template_name eq 'bm_entry') {
    foreach my $item (@{$param->{blog_loop}}) {
      $item->{entity_ref_convert_space} = $plugin->entity_ref_convert_space($item->{blog_id});
    }
    if(MT->product_code eq 'MTE') {
        $param->{entity_ref_button_icon} = $app->static_path . 'plugins/EntityRefButton/images/formatting-icons/ref.gif';
        $param->{entity_ref_button_icon_width} = 26;
        $param->{entity_ref_button_icon_height} = 19;
    }
    else {
        $param->{entity_ref_button_icon} = $app->static_path . 'plugins/EntityRefButton/images/html-ref.gif';
        $param->{entity_ref_button_icon_width} = 22;
        $param->{entity_ref_button_icon_height} = 16;
    }
  }
}

sub transform {
  my $template_name = shift;
  my ($eh, $app, $tmpl) = @_;
  my $entries = $TEMPLATES{$template_name};
  foreach my $item (@$entries) {
    my $pattern_s = $item->{pattern_s};
    my $pattern_e = $item->{pattern_e};
    my $replacement = $item->{replacement};
    $$tmpl =~ s!($pattern_s)($pattern_e)!$1$replacement$2!s;
  }
}

sub template {
  my $label = $plugin->translate('Space Conversion:');
  my $description = $plugin->translate('Convert space to non-breaking(&amp;nbsp;) space');
  my $tmpl = <<TEMPLATE_END
    <div class="setting">
    <div class="label">
    <label for="entity_ref_convert_space">$label</label>
    </div>
    <div class="field">
    <p><input type="checkbox" value="1" name="entity_ref_convert_space" id="entity_ref_convert_space"<TMPL_IF NAME=ENTITY_REF_CONVERT_SPACE> checked="checked"</TMPL_IF>>$description</p>
    </div>
    </div>
TEMPLATE_END
}

sub entity_ref_convert_space {
  my $plugin = shift;
  my ($blog_id) = @_;
  my %plugin_param;

  $plugin->load_config(\%plugin_param, 'blog:'.$blog_id);
  my $value = $plugin_param{entity_ref_convert_space};
  unless ($value) {
    $plugin->load_config(\%plugin_param, 'system');
    $value = $plugin_param{entiry_ref_convert_space};
  }
  $value;
}

sub transform_mt4 {
  my ($eh, $app, $tmpl) = @_;
  my $pattern = quotemeta(<<'HTML');
                                <a href="javascript: void 0;" title="<__trans phrase="HTML Mode" escape="html">" mt:command="set-mode-textarea" class="command-toggle-html toolbar button"><b>HTML Mode</b><s></s></a>
HTML
  my $replacement = $plugin->translate_templatized(<<'HTML');
<style type="text/css">
.editor-toolbar a.button.command-convert-entity-ref {
    display: none;
}
.editor-plaintext .editor-toolbar a.button.command-convert-entity-ref {
    display: block;
    background-image: url(<$mt:var name="entity_ref_image_dir"$>amp.gif);
}
.editor-plaintext .editor-toolbar a.button.command-convert-entity-ref:hover {
    display: block;
    background-image: url(<$mt:var name="entity_ref_image_dir"$>amp-hover.gif);
}
</style>
<script type="text/javascript">
    /* <![CDATA[ */
        MT.App.Editor.Toolbar = new Class(MT.App.Editor.Toolbar, {
        eventClick: function(event) {
            var command = this.getMouseEventCommand(event);
            if(!command) {
                return event.stop();
            }
            if(command == "convertEntityRef") {
                if(this.editor.mode == 'textarea' && this.editor.isTextSelected()) {
                    var str = this.editor.textarea.getSelectedText();
                    if(str.length > 0) {
                        str = str.replace(/&/g, "&amp;");
                        str = str.replace(/</g, "&lt;");
                        str = str.replace(/>/g, "&gt;");
                        str = str.replace(/"/g, "&quot;");
                        if(this.getCvtSpace()) {
                            str = str.replace(/ /g, "&nbsp;");
                        }
                        this.editor.insertHTML(str, true);
                    }
                }
            }
            else {
                return arguments.callee.applySuper(this, arguments);
            }
            return event.stop();
        },
        getCvtSpace: function() {
            return <$mt:var name="entity_ref_convert_space"$>;
        }
});
    /* ]]> */
</script>
                                <a href="javascript: void 0;" title="<$mt:var name="entity_ref_button_label"$>" mt:command="convert-entity-ref" class="command-convert-entity-ref toolbar button"><b><$mt:var name="entity_ref_button_label"$></b><s></s></a>
HTML
  $$tmpl =~ s!($pattern)!$1$replacement!s;
  1;
}

sub mod_params_mt4 {
  my ($eh, $app, $param, $tmpl) = @_;
  $param->{entity_ref_button_label} = $plugin->translate('Convert to character entity reference');
  $param->{entity_ref_convert_space} = $plugin->entity_ref_convert_space($app->blog->id);
  $param->{entity_ref_image_dir} = $app->static_path . 'plugins/EntityRefButton/images/';
  1;
}

1;

__END__
