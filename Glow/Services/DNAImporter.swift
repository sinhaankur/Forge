import Foundation
import UniformTypeIdentifiers

/// Parses a raw consumer-DNA export (23andMe / AncestryDNA style) entirely
/// on-device and derives coarse trait categories.
///
/// PRIVACY: This reads the file only to map a handful of known SNPs to trait
/// buckets. It returns those buckets and nothing else — the raw genotypes and
/// the file itself are never stored, logged, or transmitted. The caller applies
/// the derived traits to the on-device profile and discards the text.
enum DNAImporter {

    /// File types the picker accepts. 23andMe ships `.txt`, AncestryDNA `.csv`,
    /// some are `.tsv`; allow plain text + comma/tab-separated + zip-less exports.
    static var allowedTypes: [UTType] {
        var types: [UTType] = [.plainText, .commaSeparatedText, .text]
        if let tsv = UTType(filenameExtension: "tsv") { types.append(tsv) }
        return types
    }

    /// Derived trait categories. Any field may be nil if that SNP wasn't found.
    struct Traits {
        var aerobic: AerobicResponse?
        var caffeine: CaffeineMetabolism?
        var carb: CarbResponse?
        var lactoseTolerant: Bool?
        var vitaminD: VitaminDTendency?
        var b12: B12Methylation?

        /// Number of markers successfully read.
        var foundCount: Int {
            [aerobic != nil, caffeine != nil, carb != nil,
             lactoseTolerant != nil, vitaminD != nil, b12 != nil]
                .filter { $0 }.count
        }

        var summary: String {
            guard foundCount > 0 else {
                return "No recognized markers were found in this file. You can still set traits manually."
            }
            var lines = ["Read \(foundCount) marker\(foundCount == 1 ? "" : "s") from your file:"]
            if let a = aerobic { lines.append("• \(a.title)") }
            if let c = caffeine { lines.append("• \(c.title)") }
            if let cb = carb { lines.append("• \(cb.title)") }
            if let l = lactoseTolerant { lines.append("• \(l ? "Lactose tolerant" : "May be lactose sensitive")") }
            if let vd = vitaminD { lines.append("• \(vd.title)") }
            if let b = b12 { lines.append("• \(b.title)") }
            lines.append("\nApplied to your profile on this device only.")
            return lines.joined(separator: "\n")
        }
    }

    /// Parse the raw text into a genotype lookup, then map known SNPs to traits.
    static func parse(_ text: String) -> Traits {
        let genotypes = genotypeMap(from: text)
        var t = Traits()

        // PPARGC1A rs8192678 — Gly482Ser. C allele ~ favorable aerobic response.
        if let g = genotypes["rs8192678"] {
            t.aerobic = g.contains("C") ? .high : .normal
        }
        // CYP1A2 rs762551 — AA = fast metabolizer; C carrier = slow.
        if let g = genotypes["rs762551"] {
            t.caffeine = g.contains("C") ? .slow : .fast
        }
        // FTO rs9939609 — A allele associated with higher obesity/appetite risk;
        // TT = protective / carb-resilient.
        if let g = genotypes["rs9939609"] {
            t.carb = g.contains("A") ? .sensitive : .resilient
        }
        // MCM6 rs4988235 — T allele confers lactase persistence (tolerant);
        // GG = likely non-persistent.
        if let g = genotypes["rs4988235"] {
            t.lactoseTolerant = g.contains("T")
        }
        // Vitamin D: GC rs2282679 — G allele linked to lower circulating 25(OH)D.
        if let g = genotypes["rs2282679"] {
            t.vitaminD = g.contains("G") ? .lower : .normal
        }
        // B12 / folate methylation: MTHFR rs1801133 — T allele reduces enzyme
        // efficiency (reduced methylation).
        if let g = genotypes["rs1801133"] {
            t.b12 = g.contains("T") ? .reduced : .efficient
        }

        return t
    }

    /// Build rsid -> genotype map from a 23andMe/AncestryDNA text export.
    /// Handles `#` comment lines, tab- or comma-separated columns, and both
    /// the 23andMe layout (rsid, chrom, pos, genotype) and the AncestryDNA
    /// layout (rsid, chrom, pos, allele1, allele2).
    private static func genotypeMap(from text: String) -> [String: String] {
        var map: [String: String] = [:]
        // Only the SNPs we care about — keeps it fast and avoids holding the
        // whole genome in memory.
        let wanted: Set<String> = [
            "rs8192678", "rs762551", "rs9939609",
            "rs4988235", "rs2282679", "rs1801133",
        ]

        text.enumerateLines { line, _ in
            guard let first = line.first, first == "r" else { return } // rsIDs start with "rs"
            let cols = line.split(whereSeparator: { $0 == "\t" || $0 == "," })
                .map { $0.trimmingCharacters(in: .whitespaces) }
            guard let rsid = cols.first, wanted.contains(rsid) else { return }

            let genotype: String
            if cols.count >= 5 {
                // AncestryDNA: rsid, chrom, pos, allele1, allele2
                genotype = (cols[3] + cols[4]).uppercased()
            } else if cols.count == 4 {
                // 23andMe: rsid, chrom, pos, genotype
                genotype = cols[3].uppercased()
            } else {
                return
            }
            // Ignore no-calls ("--", "00", "II", "DD" indels we don't interpret).
            if genotype.contains("-") || genotype.contains("0") { return }
            map[rsid] = genotype
        }
        return map
    }
}
