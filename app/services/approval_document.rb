# Generates the bid approval form (PDF) from an approval's frozen snapshot — no AI involved:
# strengths come from evidence, points to confirm from missing_info, exactly as frozen at
# submission time. The locale picks the language; Japanese uses the bundled Noto Sans JP font
# and the 承認 seal, mirroring the approval banner in the UI.
class ApprovalDocument
  PAGE_SIZE = "A4".freeze
  JP_FONT_PATH = Rails.root.join("app/assets/fonts/NotoSansJP.ttf").to_s
  INK = "1E2F36".freeze
  SLATE = "326273".freeze
  TANGERINE = "E39774".freeze
  MUTED = "6B7A80".freeze

  def initialize(approval, locale: I18n.locale)
    @approval = approval
    @locale = locale.to_s.presence_in(%w[en fr ja]) || "en"
  end

  def render
    I18n.with_locale(@locale) { build.render }
  end

  def filename
    "sagasu-approval-#{@approval.id}-#{@locale}.pdf"
  end

  private

  def build
    Prawn::Fonts::AFM.hide_m17n_warning = true
    Prawn::Document.new(page_size: PAGE_SIZE, margin: 50, info: pdf_info).tap do |pdf|
      @pdf = pdf
      setup_fonts
      header
      project_details
      buyer_comment
      @approval.snapshot_groups.each { |group| group_section(group) }
      decision_block
      footer
    end
  end

  def pdf_info
    { Title: t("title"), Author: "Sagasu", CreationDate: Time.current }
  end

  # Japanese text needs the bundled TTF; English/French stay on the built-in Helvetica.
  def setup_fonts
    return unless japanese?

    @pdf.font_families.update(
      "NotoSansJP" => { normal: JP_FONT_PATH, bold: JP_FONT_PATH, italic: JP_FONT_PATH }
    )
    @pdf.font("NotoSansJP")
  end

  def japanese?
    @locale == "ja"
  end

  def header
    @pdf.text "Sagasu", size: 12, color: MUTED
    @pdf.text t("title"), size: 22, style: :bold, color: SLATE
    @pdf.move_down 4
    @pdf.text t("status.#{@approval.status}"), size: 11, color: TANGERINE, style: :bold
    rule
  end

  def project_details
    project = @approval.project
    rows = [
      [t("labels.project"), @approval.snapshot["title"].presence || project.title],
      [t("labels.buyer"), @approval.snapshot["buyer"].presence || project.user.name],
      [t("labels.client"), project.client_name.presence || "—"],
      [t("labels.area"), project.client_area.presence || "—"],
      [t("labels.budget"), budget_line(project)],
      [t("labels.submitted_at"), I18n.l(@approval.submitted_at, format: :long)]
    ]
    table(rows, column_widths: [140, @pdf.bounds.width - 140])
    @pdf.move_down 12
  end

  def budget_line(project)
    return "—" unless project.budget_amount

    "#{project.budget_amount.to_fs(:delimited)} #{project.budget_currency}"
  end

  def buyer_comment
    comment = @approval.snapshot["buyer_comment"].presence
    return unless comment

    @pdf.text t("labels.buyer_comment"), size: 11, style: :bold, color: SLATE
    @pdf.text comment, size: 10
    @pdf.move_down 12
  end

  def group_section(group)
    @pdf.start_new_page if @pdf.cursor < 200
    @pdf.text group["title"], size: 14, style: :bold, color: INK
    @pdf.move_down 6

    items = Array(group["items"])
    if items.any?
      @pdf.text t("labels.materials"), size: 10, style: :bold, color: MUTED
      rows = [[t("columns.description"), t("columns.quantity"), t("columns.unit")]] +
             items.map { |item| [item["description"], item["quantity"].presence || "—", item["unit"].presence || "—"] }
      table(rows, header: true, column_widths: [@pdf.bounds.width - 190, 95, 95])
      @pdf.move_down 10
    end

    suppliers = Array(group["suppliers"])
    return unless suppliers.any?

    @pdf.text t("labels.selected_suppliers"), size: 10, style: :bold, color: MUTED
    rows = [[t("columns.supplier"), t("columns.origin"), t("columns.strengths"), t("columns.to_confirm")]] +
           suppliers.map { |supplier| supplier_row(supplier) }
    detail = (@pdf.bounds.width - 170) / 2.0
    table(rows, header: true, column_widths: [110, 60, detail, detail])
    @pdf.move_down 14
  end

  def supplier_row(supplier)
    [
      supplier["name"],
      supplier["ai_suggested"] ? t("origin.ai") : t("origin.manual"),
      bullet_list(supplier["evidence"]),
      bullet_list(supplier["missing_info"])
    ]
  end

  def bullet_list(values)
    list = Array(values).presence
    return "—" unless list

    list.map { |value| "• #{value}" }.join("\n")
  end

  def decision_block
    @pdf.start_new_page if @pdf.cursor < 150
    rule
    @pdf.text t("decision.heading"), size: 12, style: :bold, color: SLATE
    @pdf.move_down 6

    if @approval.pending?
      @pdf.text t("decision.pending"), size: 10, color: MUTED
    else
      @pdf.text "#{t("decision.#{@approval.status}")} — #{@approval.approver.name}, " \
                "#{I18n.l(@approval.decided_at, format: :long)}", size: 10
      @pdf.text "“#{@approval.comment}”", size: 10, color: INK if @approval.comment.present?
      seal if japanese? && @approval.approved?
    end
  end

  # The 承認 seal (hanko), as on the approved banner in the UI.
  def seal
    top = @pdf.cursor
    @pdf.bounding_box([@pdf.bounds.width - 80, top], width: 60, height: 60) do
      @pdf.stroke_color = "C0392B"
      @pdf.line_width = 2
      @pdf.stroke_circle [30, 30], 28
      @pdf.text_box t("decision.seal"), at: [2, 44], width: 56, align: :center,
                                        size: 16, style: :bold, color: "C0392B"
    end
  end

  def footer
    @pdf.number_pages "#{t('footer.generated_at', time: I18n.l(Time.current, format: :short))} — <page>/<total>",
                      at: [@pdf.bounds.left, 0], size: 8, color: MUTED
  end

  def rule
    @pdf.stroke_color = SLATE
    @pdf.stroke_horizontal_rule
    @pdf.move_down 12
  end

  def table(rows, header: false, column_widths: nil)
    options = { width: @pdf.bounds.width, cell_style: { size: 9, border_color: "D9DDE0" } }
    options[:column_widths] = column_widths if column_widths
    if header
      options[:row_colors] = %w[F2F5F6 FFFFFF]
      options[:cell_style][:header] = true
    end
    @pdf.table(rows, options) do |t|
      t.row(0).font_style = :bold if header
    end
  end

  def t(key, **)
    I18n.t("approval_document.#{key}", **)
  end
end
