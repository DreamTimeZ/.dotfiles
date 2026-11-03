local M = {}

local config = require("modules.hotkeys.config")

local CELL_GAP = "   "

function M.showFormattedAlert(content, title, options)
    options = options or {}

    local formattedLines = title and {title} or {}

    local maxItemsPerLine = options.maxItemsPerLine or config.ui.maxItemsPerLine
    local items = type(content) == "table" and content or {tostring(content)}

    local lineItems = {}
    for i, item in ipairs(items) do
        table.insert(lineItems, item)

        if #lineItems >= maxItemsPerLine or i == #items then
            table.insert(formattedLines, table.concat(lineItems, CELL_GAP))
            lineItems = {}
        end
    end

    hs.alert.show(table.concat(formattedLines, "\n"), options)
end

-- The panel is centered. hs.alert anchors its top about a third down the screen and never wraps,
-- so long lists hung low and wide ones were clipped at both edges.
local panel

function M.hideShortcutPanel()
    if panel then
        panel:delete(hs.alert.defaultStyle.fadeOutDuration)
        panel = nil
    end
end

function M.showShortcutPanel(title, rows)
    M.hideShortcutPanel()
    if #rows == 0 then return end

    local style = hs.alert.defaultStyle
    local font = { name = style.textFont, size = style.textSize }
    local function text(str)
        return hs.styledtext.new(str, { font = font, color = style.textColor })
    end

    panel = hs.canvas.new({ x = 0, y = 0, w = 1, h = 1 })
    local function measure(styled)
        local size = panel:minimumTextSize(styled)
        return math.ceil(size.w), math.ceil(size.h)
    end

    local titleText = text(title)
    local titleW, lineH = measure(titleText)
    local gapW = measure(text(CELL_GAP))
    local cells = {}
    for i, row in ipairs(rows) do
        local cellText = text(row.key and string.format(config.ui.keyFormat, row.key, row.desc) or row.desc)
        local w, h = measure(cellText)
        cells[i] = { text = cellText, w = w }
        lineH = math.max(lineH, h)
    end

    local function columnWidths(perRow)
        local widths, total = {}, 0
        for i, cell in ipairs(cells) do
            local c = (i - 1) % perRow + 1
            widths[c] = math.max(widths[c] or 0, cell.w)
        end
        for c, w in ipairs(widths) do
            total = total + w + (c > 1 and gapW or 0)
        end
        return widths, total
    end

    local padding = style.padding or style.textSize / 2
    local frameExtra = 2 * padding + style.strokeWidth
    local screenFrame = hs.screen.mainScreen():frame()
    local maxWidth = screenFrame.w * config.ui.panelMaxScreenWidthFraction

    local perRow = math.min(config.ui.maxItemsPerLine, #cells)
    local widths, gridW = columnWidths(perRow)
    while perRow > 1 and gridW + frameExtra > maxWidth do
        perRow = perRow - 1
        widths, gridW = columnWidths(perRow)
    end

    local rowCount = math.ceil(#cells / perRow)
    local textW = math.max(titleW, gridW)
    local width = textW + frameExtra
    local height = lineH * (rowCount + 1) + frameExtra

    -- Sized before any element is added, so element frames never depend on resize semantics.
    panel:frame({
        x = screenFrame.x + (screenFrame.w - width) / 2,
        y = screenFrame.y + (screenFrame.h - height) / 2,
        w = width,
        h = height,
    })

    local left = padding + style.strokeWidth / 2
    local elements = {
        -- Full-canvas rectangle clipped to its path, as hs.drawing builds the hs.alert box: same 1 pt crisp edge.
        {
            type = "rectangle",
            action = "strokeAndFill",
            clipToPath = true,
            fillColor = style.fillColor,
            strokeColor = style.strokeColor,
            strokeWidth = style.strokeWidth,
            roundedRectRadii = { xRadius = style.radius, yRadius = style.radius },
        },
        {
            type = "text",
            text = titleText,
            frame = { x = left, y = left, w = textW, h = lineH },
        },
    }

    local columnX = { left }
    for c = 2, perRow do
        columnX[c] = columnX[c - 1] + widths[c - 1] + gapW
    end
    for i, cell in ipairs(cells) do
        local c = (i - 1) % perRow + 1
        local r = math.floor((i - 1) / perRow) + 1
        table.insert(elements, {
            type = "text",
            text = cell.text,
            frame = { x = columnX[c], y = left + r * lineH, w = widths[c], h = lineH },
        })
    end

    panel:appendElements(elements)
    panel:show(style.fadeInDuration)
end

return M
