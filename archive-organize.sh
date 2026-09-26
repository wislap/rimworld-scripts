#!/bin/bash
# N.E.K.O. RimWorld 归档整理脚本
# 安全模式：所有操作都是移动，不删除任何数据

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "=========================================="
echo "🗂️  N.E.K.O. RimWorld 归档整理工具"
echo "=========================================="
echo ""
echo "当前目录: $(pwd)"
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 统计函数
count_items() {
    local path=$1
    if [ -d "$path" ]; then
        find "$path" -type f 2>/dev/null | wc -l
    else
        echo "0"
    fi
}

get_size() {
    local path=$1
    if [ -d "$path" ] || [ -f "$path" ]; then
        du -sh "$path" 2>/dev/null | cut -f1
    else
        echo "0"
    fi
}

# 阶段1：创建归档目录结构
stage1_create_structure() {
    echo -e "${BLUE}📁 阶段1: 创建归档目录结构${NC}"
    
    mkdir -p archives/2026-09-15-16-investigations
    mkdir -p archives/bench-data-legacy/2026-09-05-08-legacy
    mkdir -p archives/bench-data-legacy/query-usability-experiments
    mkdir -p archives/bench-data-legacy/auto-probe-experiments
    mkdir -p archives/bench-data-legacy/v13-worlds
    mkdir -p archives/bench-results-iterations
    mkdir -p archives/bench-results-specialized/capture-experiments
    mkdir -p archives/bench-results-specialized/version-agent-tests
    mkdir -p archives/bench-results-specialized/prose-review-series
    mkdir -p archives/bench-results-specialized/storage-overlap-tests
    mkdir -p archives/bench-results-specialized/query-diagnostics
    mkdir -p archives/code-review-archive
    mkdir -p docs/setup
    
    echo -e "${GREEN}✓ 目录结构创建完成${NC}"
    echo ""
}

# 阶段2：移动调查文档
stage2_archive_investigations() {
    echo -e "${BLUE}📄 阶段2: 归档调查文档${NC}"
    local moved=0
    
    if [ -f "INVESTIGATION-2026-09-15.md" ]; then
        mv INVESTIGATION-2026-09-15.md archives/2026-09-15-16-investigations/
        echo "  ✓ INVESTIGATION-2026-09-15.md"
        ((moved++))
    fi
    
    if [ -f "INVESTIGATION-2026-09-16.md" ]; then
        mv INVESTIGATION-2026-09-16.md archives/2026-09-15-16-investigations/
        echo "  ✓ INVESTIGATION-2026-09-16.md"
        ((moved++))
    fi
    
    if [ -f "RIMWORLD-COMMUNITY-RESEARCH-2026-09-16.md" ]; then
        mv RIMWORLD-COMMUNITY-RESEARCH-2026-09-16.md archives/2026-09-15-16-investigations/
        echo "  ✓ RIMWORLD-COMMUNITY-RESEARCH-2026-09-16.md"
        ((moved++))
    fi
    
    if [ -d "investigation-20260916" ]; then
        mv investigation-20260916/ archives/2026-09-15-16-investigations/
        echo "  ✓ investigation-20260916/ ($(count_items investigation-20260916) files)"
        ((moved++))
    fi
    
    if [ -d "community-research-20260916" ]; then
        mv community-research-20260916/ archives/2026-09-15-16-investigations/
        echo "  ✓ community-research-20260916/ ($(count_items community-research-20260916) files)"
        ((moved++))
    fi
    
    echo -e "${GREEN}✓ 已移动 $moved 项调查文档${NC}"
    echo ""
}

# 阶段3：归档历史基准数据
stage3_archive_bench_data() {
    echo -e "${BLUE}💾 阶段3: 归档历史基准数据${NC}"
    local moved=0
    
    # legacy 数据
    if [ -d ".bench-data/legacy" ]; then
        local size=$(get_size .bench-data/legacy)
        mv .bench-data/legacy archives/bench-data-legacy/2026-09-05-08-legacy/
        echo "  ✓ legacy/ ($size)"
        ((moved++))
    fi
    
    # runtime-archive
    if [ -d ".bench-data/runtime-archive" ]; then
        local size=$(get_size .bench-data/runtime-archive)
        mv .bench-data/runtime-archive archives/bench-data-legacy/
        echo "  ✓ runtime-archive/ ($size)"
        ((moved++))
    fi
    
    # query-usability 系列
    for dir in .bench-data/query-usability-*; do
        if [ -d "$dir" ]; then
            local basename=$(basename "$dir")
            local size=$(get_size "$dir")
            mv "$dir" archives/bench-data-legacy/query-usability-experiments/
            echo "  ✓ $basename/ ($size)"
            ((moved++))
        fi
    done
    
    # auto-probe 系列
    for dir in .bench-data/auto-probe-* .bench-data/auto-interned-* .bench-data/auto-v4-*; do
        if [ -d "$dir" ]; then
            local basename=$(basename "$dir")
            local size=$(get_size "$dir")
            mv "$dir" archives/bench-data-legacy/auto-probe-experiments/
            echo "  ✓ $basename/ ($size)"
            ((moved++))
        fi
    done
    
    # v13 世界
    for dir in .bench-data/v13-dev-world-*; do
        if [ -d "$dir" ]; then
            local basename=$(basename "$dir")
            local size=$(get_size "$dir")
            mv "$dir" archives/bench-data-legacy/v13-worlds/
            echo "  ✓ $basename/ ($size)"
            ((moved++))
        fi
    done
    
    echo -e "${GREEN}✓ 已归档 $moved 项基准数据${NC}"
    echo ""
}

# 阶段4：归档迭代测试结果
stage4_archive_iterations() {
    echo -e "${BLUE}🔄 阶段4: 归档迭代测试结果${NC}"
    local moved=0
    
    for dir in .bench-results/iteration-1.1-20260910 \
               .bench-results/iteration-1.2-20260910 \
               .bench-results/iteration-1.2-round2-20260910 \
               .bench-results/iteration-1.3-20260912 \
               .bench-results/iteration-1.4-20260912 \
               .bench-results/iteration-1.4.1-20260912-234507; do
        if [ -d "$dir" ]; then
            local basename=$(basename "$dir")
            local size=$(get_size "$dir")
            mv "$dir" archives/bench-results-iterations/
            echo "  ✓ $basename/ ($size)"
            ((moved++))
        fi
    done
    
    echo -e "${GREEN}✓ 已归档 $moved 项迭代测试${NC}"
    echo ""
}

# 阶段5：归档专项测试
stage5_archive_specialized() {
    echo -e "${BLUE}🧪 阶段5: 归档专项测试结果${NC}"
    local moved=0
    
    # capture 实验
    for dir in .bench-results/capture-* \
               .bench-results/noexec-capture-acceptance \
               .bench-results/automatic-capture-acceptance; do
        if [ -d "$dir" ]; then
            local basename=$(basename "$dir")
            local size=$(get_size "$dir")
            mv "$dir" archives/bench-results-specialized/capture-experiments/
            echo "  ✓ $basename/ ($size)"
            ((moved++))
        fi
    done
    
    # version-agent
    for dir in .bench-results/version-agent-*; do
        if [ -d "$dir" ]; then
            local basename=$(basename "$dir")
            local size=$(get_size "$dir")
            mv "$dir" archives/bench-results-specialized/version-agent-tests/
            echo "  ✓ $basename/ ($size)"
            ((moved++))
        fi
    done
    
    # prose-review
    for dir in .bench-results/g0-prose-review-*; do
        if [ -d "$dir" ]; then
            local basename=$(basename "$dir")
            local size=$(get_size "$dir")
            mv "$dir" archives/bench-results-specialized/prose-review-series/
            echo "  ✓ $basename/ ($size)"
            ((moved++))
        fi
    done
    
    # storage-overlap
    for dir in .bench-results/storage-overlap-*; do
        if [ -d "$dir" ]; then
            local basename=$(basename "$dir")
            local size=$(get_size "$dir")
            mv "$dir" archives/bench-results-specialized/storage-overlap-tests/
            echo "  ✓ $basename/ ($size)"
            ((moved++))
        fi
    done
    
    # query 诊断
    for dir in .bench-results/query-usability-20260912 \
               .bench-results/query-retry-20260912-145939 \
               .bench-results/deepseek-flash-retry-20260912-151119; do
        if [ -d "$dir" ]; then
            local basename=$(basename "$dir")
            local size=$(get_size "$dir")
            mv "$dir" archives/bench-results-specialized/query-diagnostics/
            echo "  ✓ $basename/ ($size)"
            ((moved++))
        fi
    done
    
    # real-paired
    if [ -d ".bench-results/real-paired-v1" ]; then
        local size=$(get_size .bench-results/real-paired-v1)
        mv .bench-results/real-paired-v1 archives/bench-results-specialized/
        echo "  ✓ real-paired-v1/ ($size)"
        ((moved++))
    fi
    
    echo -e "${GREEN}✓ 已归档 $moved 项专项测试${NC}"
    echo ""
}

# 阶段6：归档代码评审
stage6_archive_reviews() {
    echo -e "${BLUE}📋 阶段6: 归档代码评审${NC}"
    local moved=0
    
    if [ -d ".review-results/20260910-full-review" ]; then
        mv .review-results/20260910-full-review archives/code-review-archive/
        echo "  ✓ 20260910-full-review/"
        ((moved++))
    fi
    
    if [ -d ".review-results" ]; then
        rmdir .review-results 2>/dev/null && echo "  ✓ 已删除空目录 .review-results/" || true
    fi
    
    echo -e "${GREEN}✓ 已归档 $moved 项代码评审${NC}"
    echo ""
}

# 创建元数据文档
create_metadata() {
    echo -e "${BLUE}📝 创建元数据文档${NC}"
    
    cat > archives/README.md << 'EOF'
# N.E.K.O. RimWorld 历史归档

本目录包含项目开发过程中的历史调查、实验数据和测试结果。

## 目录说明

- **2026-09-15-16-investigations/** - 2026年9月15-16日技术调查和社区研究
- **bench-data-legacy/** - 历史基准测试数据（2026年9月5日-12日）
- **bench-results-iterations/** - 迭代基准测试结果（iteration 1.1-1.4.1）
- **bench-results-specialized/** - 专项测试结果（capture、version-agent、prose-review等）
- **code-review-archive/** - 历史代码评审记录

## 归档时间

整理日期：$(date +%Y-%m-%d)  
归档范围：2026年9月5日 - 2026年9月16日

## 活跃数据位置

当前活跃的基准数据和测试结果仍保留在：
- `.bench-data/` - v14世界数据、debug-tools、real数据
- `.bench-results/` - 质量评审基线、资源升级测试

## 检索归档内容

所有归档文件保持原始格式，可直接使用：
\`\`\`bash
# 查找特定实验
find archives/ -name "*query-usability*"

# 检索调查文档
grep -r "RimBridge" archives/2026-09-15-16-investigations/

# 查看迭代变更
cat archives/bench-results-iterations/README.md
\`\`\`
EOF

    cat > archives/bench-results-iterations/README.md << 'EOF'
# 迭代基准测试结果

## 迭代记录

| 迭代 | 日期 | 大小 | 主要变更 |
|------|------|------|----------|
| 1.1 | 2026-09-10 | 73MB | 初始评估框架建立 |
| 1.2 | 2026-09-10 | 71MB | 查询性能优化 |
| 1.2-round2 | 2026-09-10 | 69MB | 第二轮验证 |
| 1.3 | 2026-09-12 | 113MB | 扩展测试用例 |
| 1.4 | 2026-09-12 | 173MB | 完整场景覆盖 |
| 1.4.1 | 2026-09-12 | 382MB | 错误处理改进 |

## 保留的活跃基线

`iteration-1.1-quality-review` (40MB) 保留在 `.bench-results/` 作为质量评审基线。

## 数据格式

所有结果包含：
- `cases.json` - 测试用例定义
- `manifest.json` - 运行清单
- `runs/` - 执行记录
- `review/packets/` - 评审数据包
EOF

    echo -e "${GREEN}✓ 元数据文档创建完成${NC}"
    echo ""
}

# 生成归档报告
generate_report() {
    echo ""
    echo "=========================================="
    echo "📊 归档统计报告"
    echo "=========================================="
    echo ""
    
    echo "归档目录大小:"
    du -sh archives/* 2>/dev/null | sed 's/^/  /'
    echo ""
    echo "总归档大小: $(get_size archives)"
    echo ""
    
    echo "活跃数据位置:"
    echo "  .bench-data/     $(get_size .bench-data)"
    echo "  .bench-results/  $(get_size .bench-results)"
    echo "  rimworld-bench/  $(get_size rimworld-bench)"
    echo ""
    
    echo "归档文件统计:"
    echo "  总文件数: $(count_items archives)"
    echo ""
}

# 主菜单
show_menu() {
    echo ""
    echo "请选择操作："
    echo ""
    echo "  ${GREEN}1${NC} - 阶段1: 创建目录结构（安全）"
    echo "  ${GREEN}2${NC} - 阶段2: 归档调查文档（~2MB）"
    echo "  ${GREEN}3${NC} - 阶段3: 归档历史基准数据（~920MB）"
    echo "  ${GREEN}4${NC} - 阶段4: 归档迭代测试结果（~881MB）"
    echo "  ${GREEN}5${NC} - 阶段5: 归档专项测试（~180MB）"
    echo "  ${GREEN}6${NC} - 阶段6: 归档代码评审"
    echo ""
    echo "  ${YELLOW}A${NC} - 执行全部阶段（完整归档）"
    echo "  ${YELLOW}Q${NC} - 快速模式（阶段1+2，安全轻量）"
    echo ""
    echo "  ${BLUE}R${NC} - 生成归档报告"
    echo "  ${BLUE}X${NC} - 退出"
    echo ""
    echo -n "请输入选项: "
}

# 主流程
main() {
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1)
                stage1_create_structure
                create_metadata
                ;;
            2)
                stage2_archive_investigations
                ;;
            3)
                echo -e "${YELLOW}⚠️  警告: 将移动约920MB数据${NC}"
                echo -n "确认继续? (y/N): "
                read -r confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    stage3_archive_bench_data
                else
                    echo "已取消"
                fi
                ;;
            4)
                echo -e "${YELLOW}⚠️  警告: 将移动约881MB数据${NC}"
                echo -n "确认继续? (y/N): "
                read -r confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    stage4_archive_iterations
                else
                    echo "已取消"
                fi
                ;;
            5)
                echo -e "${YELLOW}⚠️  警告: 将移动约180MB数据${NC}"
                echo -n "确认继续? (y/N): "
                read -r confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    stage5_archive_specialized
                else
                    echo "已取消"
                fi
                ;;
            6)
                stage6_archive_reviews
                ;;
            A|a)
                echo -e "${YELLOW}⚠️  警告: 将执行完整归档，移动约2GB数据${NC}"
                echo -n "确认继续? (y/N): "
                read -r confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    stage1_create_structure
                    stage2_archive_investigations
                    stage3_archive_bench_data
                    stage4_archive_iterations
                    stage5_archive_specialized
                    stage6_archive_reviews
                    create_metadata
                    generate_report
                    echo -e "${GREEN}✅ 完整归档完成！${NC}"
                else
                    echo "已取消"
                fi
                ;;
            Q|q)
                echo "执行快速模式（阶段1+2）..."
                stage1_create_structure
                stage2_archive_investigations
                create_metadata
                echo -e "${GREEN}✅ 快速归档完成！${NC}"
                ;;
            R|r)
                generate_report
                ;;
            X|x)
                echo "退出归档工具"
                exit 0
                ;;
            *)
                echo -e "${YELLOW}无效选项，请重试${NC}"
                ;;
        esac
        
        echo ""
        echo "按 Enter 继续..."
        read -r
    done
}

# 如果脚本带参数直接执行
if [ $# -gt 0 ]; then
    case $1 in
        --quick)
            stage1_create_structure
            stage2_archive_investigations
            create_metadata
            generate_report
            ;;
        --full)
            stage1_create_structure
            stage2_archive_investigations
            stage3_archive_bench_data
            stage4_archive_iterations
            stage5_archive_specialized
            stage6_archive_reviews
            create_metadata
            generate_report
            ;;
        --report)
            generate_report
            ;;
        *)
            echo "用法: $0 [--quick|--full|--report]"
            echo ""
            echo "  --quick   快速模式（阶段1+2）"
            echo "  --full    完整归档"
            echo "  --report  生成报告"
            echo ""
            echo "不带参数运行进入交互模式"
            exit 1
            ;;
    esac
else
    main
fi
