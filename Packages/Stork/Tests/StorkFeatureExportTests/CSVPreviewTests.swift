import Testing
@testable import StorkFeatureExport

@Suite("CSV preview table")
struct CSVPreviewTests {
    @Test func dropsIdentifierColumnsFromThePreviewOnly() {
        let csv = "delivery_id,date,baby_id,sex\nABC,2026-01-01T00:00:00Z,XYZ,male\nDEF,2026-01-02T00:00:00Z,UVW,female"
        let table = CSVPreviewTable.make(csv: csv, maxRows: 8)
        #expect(table[0] == ["date", "sex"])
        #expect(table[1] == ["2026-01-01T00:00:00Z", "male"])
        #expect(table.count == 3)
    }

    @Test func parsesQuotedFieldsAndLimitsRows() {
        let csv = "delivery_id,note,n\nA,\"a, \"\"b\"\"\",1\nB,x,2\nC,y,3"
        let table = CSVPreviewTable.make(csv: csv, maxRows: 2)
        #expect(table[1] == ["a, \"b\"", "1"])
        #expect(table.count == 3)
    }
}
